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
tools_config;
% config;
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
[~, lus_file_name, ~] = fileparts(char(lus_file_path));
addpath(model_path);
load_system(model_full_path);
%fullfile(output_dir, strcat(lus_file_name, ext))
%delete(fullfile(output_dir, strcat(lus_file_name, ext)));
%copyfile(lus_file_path, output_dir);


if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
%% Copile the lustre code to C
err = LustrecUtils.compile_lustre_to_Cbinary(lus_file_path,...
    LusValidateUtils.name_format(node_name), ...
    output_dir, ...
    LUSTREC,LUCTREC_INCLUDE_DIR);
if err
    lustrec_failed = 1;
    return
end



%% Get model inports informations
[inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);

%% Create the input struct for the simulation
numberOfInports = numel(inports);
nb_steps = 100;
if exist('min_max_constraints','var') && numel(min_max_constraints) > 0
    IMIN = min_max_constraints{:,2};
    IMAX = min_max_constraints{:,3};
else
    IMIN = -100;
    IMAX = 100;
end
[input_struct, simulation_step, stop_time] = SLXUtils.get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN);

lustre_input_values = LustrecUtils.getLustreInputValuesFormat(input_struct, nb_steps);

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
GUIUtils.update_status('Simulating model');
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
