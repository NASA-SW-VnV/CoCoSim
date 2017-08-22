function [valid,lustrec_failed, ...
    lustrec_binary_failed, sim_failed] ...
    = compare_slx_lus(model_full_path, lus_file_path, node_name, ...
    output_dir, show_models, min_max_constraints)



if ~exist('show_models', 'var')
    show_models = 0;
elseif show_models
    open(model_full_path);
end

%% define configuration variables
% cocosim_config;
config;
assignin('base', 'SOLVER', 'V');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
OldPwd = pwd;

%% define default outputs
lustrec_failed=0;
lustrec_binary_failed=0;
sim_failed=0;
valid = 0;
%%
[model_path, slx_file_name, ~] = fileparts(char(model_full_path));
[~, lus_file_name, ext] = fileparts(char(lus_file_path));
addpath(model_path);
load_system(model_full_path);
%fullfile(output_dir, strcat(lus_file_name, ext))
%delete(fullfile(output_dir, strcat(lus_file_name, ext)));
%copyfile(lus_file_path, output_dir);


if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
cd(output_dir);
%% Copile the lustre code to C
command = sprintf('%s -I "%s" -node %s "%s"',...
    LUSTREC,LUCTREC_INCLUDE_DIR, LusValidateUtils.name_format(node_name), lus_file_path);
msg = sprintf('LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'validation', '');
GUIUtils.update_status('Runing Lustrec compiler');
[status, lustre_out] = system(command);
if status
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    msg = sprintf('lustrec failed for model "%s"',lus_file_name);
    display_msg(msg, MsgType.INFO, 'validation', '');
    display_msg(msg, MsgType.ERROR, 'validation', '');
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    display_msg(lustre_out, MsgType.DEBUG, 'validation', '');
    lustrec_failed = 1;
    cd(OldPwd);
    return
end

%% generate binary from C code
msg = sprintf('start compiling model "%s"\n',lus_file_name);
display_msg(msg, MsgType.INFO, 'validation', '');
makefile_name = fullfile(output_dir,strcat(lus_file_name,'.makefile'));
command = sprintf('make -f "%s"', makefile_name);
msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'validation', '');
[status, make_out] = system(command);
if status
    err = sprintf('Compilation failed for model "%s" ',lus_file_name);
    display_msg(err, MsgType.ERROR, 'validation', '');
    display_msg(err, MsgType.DEBUG, 'validation', '');
    display_msg(make_out, MsgType.DEBUG, 'validation', '');
    command = sprintf('rm %s.makefile %s.c %s.h %s.o %s.lusic  %s_main.* %s_alloc.h %s_sfun.mexa64',...
        lus_file_name, lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name);
    system(command);
    command = sprintf('rm *.o input_values outputs_values ');
    system(command);
    command = sprintf('rm -r slprj');
    system(command);
    cd(OldPwd);
    return
end

%% Get model inports informations
%TODO: Need to be optimized
GUIUtils.update_status('Generating Lustrec outputs');
load_system(model_full_path);

rt = sfroot;
m = rt.find('-isa', 'Simulink.BlockDiagram');
events = m.find('-isa', 'Stateflow.Event');
inputEvents = events.find('Scope', 'Input');
inputEvents_names = inputEvents.get('Name');
code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
warning off;
evalin('base',code_on);
block_paths = find_system(slx_file_name, 'SearchDepth',1, 'BlockType', 'Inport');
inports = [];
for i=1:numel(block_paths)
    block = block_paths{i};
    block_ports_dts = get_param(block, 'CompiledPortDataTypes');
    DataType = block_ports_dts.Outport;
    dimension_struct = get_param(block,'CompiledPortDimensions');
    dimension = dimension_struct.Outport;
    if numel(dimension)== 2 && dimension(1)==1
        dimension = dimension(2);
    end
    inports = [inports, struct('Name',BUtils.naming_alone(block),...
        'DataType', DataType, 'Dimension', dimension)];
    
end
code_on=sprintf('%s([], [], [], ''term'')', slx_file_name);
evalin('base',code_on);
warning on;
numberOfInports = numel(inports);

%% Create the input struct for the simulation
stop_time = 1000;
try
    min = SLXUtils.get_BlockDiagram_SampleTime(slx_file_name);
    if  min==0 || isnan(min) || min==Inf
        simulation_step = 1;
    else
        simulation_step = min;
    end
    
catch
    simulation_step = 1;
end
nb_steps = stop_time/simulation_step +1;
IMAX = 100; %IMAX for randi the max born for random number
IMIN = -5;

input_struct.time = (0:simulation_step:stop_time)';
input_struct.signals = [];
number_of_inputs = 0;
for i=1:numberOfInports
    input_struct.signals(i).name = inports(i).Name;
    dim = inports(i).Dimension;
    if exist('min_max_constraints', 'var') && ~isempty(min_max_constraints)
        IMIN = min_max_constraints{i,2};
        IMAX = min_max_constraints{i,3};
    end
    if find(strcmp(inputEvents_names,inports(i).Name))
        input_struct.signals(i).values = square((numberOfInports-i+1)*rand(1)*input_struct.time);
        input_struct.signals(i).dimensions = 1;%dim;
    elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).DataType),'bool')
        input_struct.signals(i).values = LusValidateUtils.construct_random_booleans(nb_steps, IMIN, IMAX, dim);
        input_struct.signals(i).dimensions = dim;
    elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).DataType),'int')
        input_struct.signals(i).values = LusValidateUtils.construct_random_integers(nb_steps, IMIN, IMAX, inports(i).DataType, dim);
        input_struct.signals(i).dimensions = dim;
    elseif strcmp(inports(i).DataType,'single')
        input_struct.signals(i).values = single(LusValidateUtils.construct_random_doubles(nb_steps, IMIN, IMAX,dim));
        input_struct.signals(i).dimensions = dim;
    else
        input_struct.signals(i).values = LusValidateUtils.construct_random_doubles(nb_steps, IMIN, IMAX,dim);
        input_struct.signals(i).dimensions = dim;
    end
    if numel(dim)==1
        number_of_inputs = number_of_inputs + nb_steps*dim;
    else
        number_of_inputs = number_of_inputs + nb_steps*(dim(1) * dim(2));
    end
end

%% take input struct if defined by the user
%TODO: improve it
try
    input_struct = evalin('base','user_input_struct');
catch
end

%% Translate input_stract to lustre format (inline the inputs)
if numberOfInports>=1
    lustre_input_values = ones(number_of_inputs,1);
    index = 0;
    for i=0:nb_steps-1
        for j=1:numberOfInports
            dim = input_struct.signals(j).dimensions;
            if numel(dim)==1
                index2 = index + dim;
                lustre_input_values(index+1:index2) = input_struct.signals(j).values(i+1,:)';
            else
                index2 = index + (dim(1) * dim(2));
                yout_values = [];
                y = input_struct.signals(j).values(:,:,i+1);
                for idr=1:dim(1)
                    yout_values = [yout_values; y(idr,:)'];
                end
                lustre_input_values(index+1:index2) = yout_values;
            end
            
            index = index2;
        end
    end
    
else
    lustre_input_values = ones(1*nb_steps,1);
end


%% print lustre inputs in a file
values_file = fullfile(output_dir, 'input_values');
fid = fopen(values_file, 'w');
for i=1:numel(lustre_input_values)
    value = [num2str(lustre_input_values(i),'%.60f') '\n'];
    fprintf(fid, value);
end
fclose(fid);


%% Simulate the model
msg = sprintf('Simulating model "%s"\n',slx_file_name);
display_msg(msg, MsgType.INFO, 'validation', '');
GUIGUIUtils.update_status('Simulating model');
try
    configSet = Simulink.ConfigSet;%copy(getActiveConfigSet(file_name));
    set_param(configSet, 'Solver', 'FixedStepDiscrete');
    set_param(configSet, 'FixedStep', num2str(simulation_step));
    set_param(configSet, 'StartTime', '0.0');
    set_param(configSet, 'StopTime',  num2str(stop_time));
    set_param(configSet, 'SaveFormat', 'Structure');
    set_param(configSet, 'SaveOutput', 'on');
    set_param(configSet, 'SaveTime', 'on');
    
    if numberOfInports>=1
        set_param(configSet, 'SaveState', 'on');
        set_param(configSet, 'StateSaveName', 'xout');
        set_param(configSet, 'OutputSaveName', 'yout');
        set_param(configSet, 'ExtMode', 'on');
        set_param(configSet, 'LoadExternalInput', 'on');
        set_param(configSet, 'ExternalInput', 'input_struct');
        hws = get_param(slx_file_name, 'modelworkspace');
        hws.assignin('input_struct',eval('input_struct'));
        assignin('base','input_struct',input_struct);
        if show_models
            open(slx_file_name)
        end
        warning off;
        simOut = sim(slx_file_name, configSet);
        warning on;
    else
        if show_models
            open(slx_file_name)
        end
        warning off;
        simOut = sim(slx_file_name, configSet);
        warning on;
    end
    
    %% extract lustre outputs from lustre binary
    lustre_binary = strcat(lus_file_name,'_',LusValidateUtils.name_format(node_name));
    command  = sprintf('./%s  < input_values > outputs_values',lustre_binary);
    [status, binary_out] =system(command);
    if status
        err = sprintf('lustrec binary failed for model "%s"',lus_file_name,binary_out);
        display_msg(err, MsgType.ERROR, 'validation', '');
        display_msg(err, MsgType.DEBUG, 'validation', '');
        display_msg(binary_out, MsgType.DEBUG, 'validation', '');
        lustrec_binary_failed = 1;
        %             close_system(model_full_path,0);
        %             bdclose('all')
        command = sprintf('!rm %s.makefile %s.c %s.h %s.o %s.lusic  %s_main.* %s_alloc.h %s_sfun.mexa64 %s',...
            lus_file_name, lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name,lus_file_name,lustre_binary);
        system(command);
        command = sprintf('!rm *.o input_values outputs_values ');
        system(command);
        command = sprintf('!rm -r slprj');
        system(command);
        cd(OldPwd);
        return
    end
    
    %% compare Simulin outputs and Lustre outputs
    GUIUtils.update_status('Compare Simulink outputs and lustrec outputs');
    yout = get(simOut,'yout');
    yout_signals = yout.signals;
    assignin('base','yout',yout);
    assignin('base','yout_signals',yout_signals);
    numberOfOutputs = numel(yout_signals);
    outputs_array = importdata('outputs_values','\n');
    valid = true;
    error_index = 1;
    eps = 1e-3;
    index_out = 0;
    for i=0:nb_steps-1
        for k=1:numberOfOutputs
            dim = yout_signals(k).dimensions;
            if numel(dim)==2
                yout_values = [];
                y = yout_signals(k).values(:,:,i+1);
                for idr=1:dim(1)
                    yout_values = [yout_values; y(idr,:)'];
                end
                dim = dim(1)*dim(2);
            else
                yout_values = yout_signals(k).values(i+1,:);
            end
            for j=1:dim
                index_out = index_out + 1;
                output_value = regexp(outputs_array{index_out},'\s*:\s*','split');
                if ~isempty(output_value)
                    output_val_str = output_value{2};
                    output_val = str2num(output_val_str(2:end-1));
                    if yout_values(j)==inf
                        diff=0;
                    else
                        diff = abs(yout_values(j)-output_val);
                    end
                    valid = valid && (diff<eps);
                    if  ~valid
                        diff_name =  BUtils.naming_alone(yout_signals(k).blockName);
%                         diff_blockName = yout_signals(k).blockName;
                        error_index = i+1;
                        break
                    end
                else
                    warn = sprintf('strange behavour of output %s',outputs_array{numberOfOutputs*i+k});
                    display_msg(warn, MsgType.WARNING, 'validation', '');
                    valid = 0;
                    break;
                end
            end
            if  ~valid
                break;
            end
        end
        if  ~valid
            break;
        end
    end
    
    %% show the counter example
    if ~valid
        GUIUtils.update_status('Translation is not valid');
        f_msg = sprintf('translation for model "%s" is not valid \n',slx_file_name);
        display_msg(f_msg, MsgType.RESULT, 'validation', '');
        f_msg = sprintf('Here is the counter example:\n');
        display_msg(f_msg, MsgType.RESULT, 'validation', '');
        index_out = 0;
        for i=0:error_index-1
            f_msg = sprintf('*****step : %d**********\n',i+1);
            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
            f_msg = sprintf('*****inputs: \n');
            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
            for j=1:numberOfInports
                dim = input_struct.signals(j).dimensions;
                if numel(dim)==1
                    in = input_struct.signals(j).values(i+1,:);
                    name = input_struct.signals(j).name;
                    for k=1:dim
                        f_msg = sprintf('input %s_%d: %f\n',name,k,in(k));
                        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                    end
                else
                    in = input_struct.signals(j).values(:,:,i+1);
                    name = input_struct.signals(j).name;
                    for dim1=1:dim(1)
                        for dim2=1:dim(2)
                            f_msg = sprintf('input %s_%d_%d: %10.10f\n',name,dim1,dim2,in(dim1, dim2));
                            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                        end
                    end
                end
            end
            f_msg = sprintf('*****outputs: \n');
            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
            for k=1:numberOfOutputs
                dim = yout_signals(k).dimensions;
                if numel(dim)==2
                    %                                 if dim(1)>1
                    yout_values = [];
                    y = yout_signals(k).values(:,:,i+1);
                    for idr=1:dim(1)
                        yout_values = [yout_values; y(idr,:)'];
                    end
                    %                                 else
                    %                                     y = yout_signals(k).values(:,:,i+1);
                    %                                     yout_values = y(1,:)';
                    %                                 end
                    dim = dim(1)*dim(2);
                else
                    yout_values = yout_signals(k).values(i+1,:);
                end
                for j=1:dim
                    index_out = index_out + 1;
                    output_value = regexp(outputs_array{index_out},'\s*:\s*','split');
                    if ~isempty(output_value)
                        output_name = output_value{1};
                        output_val = output_value{2};
                        output_val = str2num(output_val(2:end-1));
                        output_name1 = BUtils.naming_alone(yout_signals(k).blockName);
                        f_msg = sprintf('output %s(%d): %10.16f\n',output_name1, j, yout_values(j));
                        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                        f_msg = sprintf('Lustre output %s: %10.16f\n',output_name,output_val);
                        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                    else
                        f_msg = sprintf('strang behavour of output %s',outputs_array{numberOfOutputs*i+k});
                        display_msg(f_msg, MsgType.WARNING, 'CEX', '');
                        return;
                    end
                end
            end
            
        end
        f_msg = sprintf('difference between outputs %s is :%2.10f\n',diff_name, diff);
        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
    else
        GUIUtils.update_status('Translation is valid');
        msg = sprintf('Translation for model "%s" is valid \n',slx_file_name);
        display_msg(msg, MsgType.RESULT, 'CEX', '');
    end
    cd(OldPwd);
catch ME
    msg = sprintf('simulation failed for model "%s" :\n%s\n%s',slx_file_name,ME.identifier,ME.message);
    display_msg(msg, MsgType.ERROR, 'validation', '');
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    sim_failed = 1;
    valid = 0;
    cd(OldPwd);
    return
end
%% report
f_msg = ['\n Simulation Input (workspace) input_struct \n'];
f_msg = [f_msg 'Simulation Output (workspace) : yout_signals \n'];
f_msg = [f_msg 'LustreC binary Input ' fullfile(output_dir,'input_values') '\n'];
f_msg = [f_msg 'LustreC binary Output ' fullfile(output_dir,'outputs_values') '\n'];
display_msg(f_msg, MsgType.RESULT, 'validation', '');


cd(OldPwd)


end