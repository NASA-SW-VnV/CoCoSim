classdef SLXUtils
    %SLXUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        %% Try to calculate Block sample time using the model
        function [st, ph, Clocks] = getModelCompiledSampleTime(file_name)
            st = 1;
            ph = 0;
            Clocks = {};
            try
                warning off;
                ts = Simulink.BlockDiagram.getSampleTimes(file_name);
                warning on;
            catch ME
                display_msg(ME.getReport(), MsgType.ERROR, 'SLXUtils.getModelCompiledSampleTime', '' );
                st = 1;
                return;
            end
            T = [];
            P = [];
            for t=ts
                v = t.Value;
                if ~isempty(v) && isnumeric(v)
                    sv = v(1);
                    if numel(v) >= 2, pv = v(2); else, pv = 0; end
                    if ~(isnan(sv) || sv==Inf)
                        T(end +1) = sv;
                        P(end +1) = pv;
                        Clocks{end+1} = [sv, pv];
                    end
                end
            end
            if isempty(P)
                P = 0;
            end
            if isempty(T)
                return;
            end
            if prod(P/P(1)) == 1
                st = MatlabUtils.gcd(T);
                ph = mod(P(1), st);
            else
                st = MatlabUtils.gcd([T, P]);
                ph = 0;
            end
            %st = gcd(st*10000,tv*10000)/10000;
        end
        
        
        %% get the value of a parameter
        function [paramValue, status] = evalParam(model, param)
            status = 0;
            if isempty(regexp(param, '^[a-zA-Z]', 'match'))
                %paramValue = str2double(param);
                paramValue = str2num(param);
            elseif strcmp(param, 'true') ...
                    ||strcmp(param, 'false')
                paramValue = evalin('base', param);
            else
                % this is the case of variable from model workspace
                hws = get_param(model, 'modelworkspace') ;
                if isvarname(param) && hasVariable(hws, param)
                    paramValue = getVariable(hws, param);
                else
                    try
                        paramValue = evalin('base',param);
                    catch
                        status = 1;
                        paramValue = 0;
                        return;
                    end
                end
            end
            
        end
        %% run constants files
        function run_constants_files(const_files)
            const_files_bak = const_files;
            try
                const_files = evalin('base', const_files);
            catch
                const_files = const_files_bak;
            end
            
            if iscell(const_files)
                for i=1:numel(const_files)
                    if strcmp(const_files{i}(end-1:end), '.m')
                        evalin('base', ['run ' const_files{i} ';']);
                    else
                        vars = load(const_files{i});
                        field_names = fieldnames(vars);
                        for j=1:numel(field_names)
                            % base here means the current Matlab workspace
                            assignin('base', field_names{j}, vars.(field_names{j}));
                        end
                    end
                end
            elseif ischar(const_files)
                if strcmp(const_files(end-1:end), '.m')
                    evalin('base', ['run ' const_files ';']);
                else
                    vars = load(const_files);
                    field_names = fieldnames(vars);
                    for j=1:numel(field_names)
                        % base here means the current Matlab workspace
                        assignin('base', field_names{j}, vars.(field_names{j}));
                    end
                end
            end
        end
        
        %% detecte if it is already pre-processed
        function already_pp = isAlreadyPP(model_path)
            [~, model, ~ ] = fileparts(model_path);
            if ~bdIsLoaded(model); load_system(model_path); end
            hws = get_param(model, 'modelworkspace') ;
            already_pp = hasVariable(hws,'already_pp') && getVariable(hws,'already_pp') == 1;
        end
        
        %%
        function [model_inputs_struct, inputEvents_names] = get_model_inputs_info(model_full_path)
            %TODO: Need to be optimized
            model_inputs_struct = [];
            try
                load_system(model_full_path);
            catch ME
                error(ME.getReport());
                return;
            end
            [~, slx_file_name, ~] = fileparts(model_full_path);
            rt = sfroot;
            m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', slx_file_name);
            events = m.find('-isa', 'Stateflow.Event');
            inputEvents = events.find('Scope', 'Input');
            inputEvents_names = inputEvents.get('Name');
            code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
            warning off;
            evalin('base',code_on);
            block_paths = find_system(slx_file_name, 'SearchDepth',1, 'BlockType', 'Inport');
            for i=1:numel(block_paths)
                block = block_paths{i};
                block_ports_dts = get_param(block, 'CompiledPortDataTypes');
                DataType = block_ports_dts.Outport;
                dimension_struct = get_param(block,'CompiledPortDimensions');
                dimension = dimension_struct.Outport;
                if numel(dimension)== 2 && dimension(1)==1
                    dimension = dimension(2);
                elseif numel(dimension) >= 3
                    dimension = dimension(2:end);
                end
                model_inputs_struct = [model_inputs_struct, struct('name',BUtils.naming_alone(block),...
                    'datatype', DataType, 'dimension', dimension)];
                
            end
            code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
            evalin('base',code_off);
            warning on;
        end
        
        %% create random vector test
        function [input_struct, ...
                simulation_step, ...
                stop_time] = get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN)
            if ~exist('inputEvents_names', 'var')
                inputEvents_names = {};
            end
            if ~exist('nb_steps', 'var')
                nb_steps = 100;
            end
            if ~exist('IMAX', 'var')
                IMAX = 500;
            end
            if ~exist('IMIN', 'var')
                IMIN = -500;
            end
            numberOfInports = numel(inports);
            try
                min = SLXUtils.getModelCompiledSampleTime(slx_file_name);
                if  min==0 || isnan(min) || min==Inf
                    simulation_step = 1;
                else
                    simulation_step = min;
                end
                
            catch
                simulation_step = 1;
            end
            stop_time = (nb_steps - 1)*simulation_step;
            input_struct.time = (0:simulation_step:stop_time)';
            input_struct.signals = [];
            for i=1:numberOfInports
                input_struct.signals(i).name = inports(i).name;
                if isfield(inports(i), 'dimension')
                    dim = inports(i).dimension;
                else
                    dim = 1;
                end
                if numel(IMIN) >= i && numel(IMAX) >= i
                    min = IMIN(i);
                    max = IMAX(i);
                else
                    min = IMIN(1);
                    max = IMAX(1);
                end
                if find(strcmp(inputEvents_names,inports(i).name))
                    input_struct.signals(i).values = square((numberOfInports-i+1)*rand(1)*input_struct.time);
                    input_struct.signals(i).dimensions = 1;
                elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).datatype),'bool')
                    input_struct.signals(i).values = LusValidateUtils.construct_random_booleans(nb_steps, min, max, dim);
                    input_struct.signals(i).dimensions = dim;
                elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).datatype),'int')
                    input_struct.signals(i).values = LusValidateUtils.construct_random_integers(nb_steps, min, max, inports(i).datatype, dim);
                    input_struct.signals(i).dimensions = dim;
                elseif strcmp(inports(i).datatype,'single')
                    input_struct.signals(i).values = single(LusValidateUtils.construct_random_doubles(nb_steps, min, max, dim));
                    input_struct.signals(i).dimensions = dim;
                else
                    input_struct.signals(i).values = LusValidateUtils.construct_random_doubles(nb_steps, min, max, dim);
                    input_struct.signals(i).dimensions = dim;
                end
                
            end
            
        end
        
        %% Simulate the model
        function simOut = simulate_model(slx_file_name, ...
                input_struct, ...
                simulation_step,...
                stop_time,...
                numberOfInports,...
                show_models)
            configSet = Simulink.ConfigSet;
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
        end
        
        %%
        function [new_model_path, new_model_name] = crete_model_from_subsystem(file_name, block_name, output_dir )
            block_name_adapted = BUtils.adapt_block_name(MatlabUtils.naming(LusValidateUtils.name_format(block_name)));
            new_model_name = strcat(file_name,'_', block_name_adapted);
            new_model_name = BUtils.adapt_block_name(new_model_name);
            new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));
            if exist(new_model_path,'file')
                if bdIsLoaded(new_model_name)
                    close_system(new_model_name,0)
                end
                delete(new_model_path);
            end
            close_system(new_model_name,0);
            model_handle = new_system(new_model_name);
            if getSimulinkBlockHandle(strcat(block_name, '/Reset'))>0
                add_block(block_name, ...
                    strcat(new_model_name, '/tmp'));
                delete_block( strcat(new_model_name, '/tmp','/Reset'));
                Simulink.BlockDiagram.expandSubsystem( strcat(new_model_name, '/tmp'));
            else
                Simulink.SubSystem.copyContentsToBlockDiagram(block_name, model_handle)
            end
            %% Save system
            save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);
            close_system(file_name,0);
        end
        
        %%
        
        function [new_model_name, status] = makeharness(T, subsys_path, output_dir, postfix_name)
            % the model should be already loaded and subsys_path is the
            % path to the subsystem or the model name.
            if nargin < 4
                postfix_name = '_harness';
            end
            new_model_name = '';
            status = 0;
            try
                if isempty(T)
                    display_msg('Tests struct is empty no test to be created',...
                        MsgType.ERROR, 'makeharness', '');
                    return;
                end
                if ~isfield(T(1), 'time') || ~isfield(T(1), 'signals')
                    display_msg('Tests struct should have "signals" and "time" field"',...
                        MsgType.ERROR, 'makeharness', '');
                    return;
                end
                model_full_path = MenuUtils.get_file_name(subsys_path);
                [model_dir, modelName, ext] = fileparts(model_full_path);
                if nargin < 3 || isempty(output_dir)
                    output_dir = model_dir;
                end
                
                %get CompiledPortDataTypes of inports
                Inportsblocks = find_system(subsys_path, 'SearchDepth',1,'BlockType','Inport');
                compile_cmd = strcat(modelName, '([],[],[],''compile'')');
                eval (compile_cmd);
                compiledPortDataTypes = get_param(Inportsblocks,'CompiledPortDataTypes');
                compiledPortwidths = get_param(Inportsblocks,'CompiledPortWidths');
                InportsDTs = cellfun(@(x) x.Outport, compiledPortDataTypes);
                term_cmd = strcat(modelName, '([],[],[],''term'')');
                eval (term_cmd);
                InportsWidths = cellfun(@(x) x.Outport, compiledPortwidths);
                if prod(InportsWidths) > 1
                    display_msg('Make harness model does not support Multidimensional Signals',...
                        MsgType.ERROR, 'makeharness', '');
                    return;
                end
                [~, subsys_name, ~] = fileparts(subsys_path);
                sampleTime = SLXUtils.getModelCompiledSampleTime(subsys_name);
                if numel(sampleTime) == 1
                    sampleTime = [sampleTime, 0];
                end
                
                newBaseName = strcat(modelName, postfix_name);
                close_system(newBaseName, 0);
                new_model_name = fullfile(output_dir, strcat(newBaseName, ext));
                if exist(newBaseName, 'file'), delete(newBaseName);end
                if ~exist(new_model_name, 'file'), copyfile(model_full_path, new_model_name);end
                
                
                % create new model
                newSubName = fullfile(newBaseName, subsys_name);
                
                new_system(newBaseName);
                
                if contains(subsys_path, filesep)
                    add_block(subsys_path, newSubName);
                else
                    add_block('built-in/Subsystem', fullfile(newBaseName, subsys_name));
                    Simulink.BlockDiagram.copyContentsToSubSystem...
                        (subsys_path,  newSubName);
                end
                NewSubPortHandles = get_param(newSubName, 'PortHandles');
                nb_inports = numel(NewSubPortHandles.Inport);
                nb_outports = numel(NewSubPortHandles.Outport);
                m = max(nb_inports, nb_outports);
                set_param(newSubName, 'Position', [350    50   510   (50+30*m)]);
                % add outports
                for i=1:nb_outports
                    p = get_param(NewSubPortHandles.Outport(i), 'Position');
                    x = p(1) + 50;
                    y = p(2);
                    outport_name = strcat(newBaseName,'/Out',num2str(i));
                    outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                        outport_name,...
                        'MakeNameUnique', 'on', ...
                        'Position',[(x+10) (y) (x+30) (y+20)]);
                    outportPortHandle = get_param(outport_handle,'PortHandles');
                    add_line(newBaseName,...
                        NewSubPortHandles.Outport(i), outportPortHandle.Inport(1),...
                        'autorouting', 'on');
                end
                
                % add convertion subsystem with rate transitions
                convertSys = fullfile(newBaseName, 'Converssion');
                add_block('built-in/Subsystem', convertSys, ...
                    'Position', [270    50   290   (50+30*m)], ...
                    'BackgroundColor', 'black', ...
                    'ForegroundColor', 'black');
                
                for i=1:nb_inports
                    x = 100; y=100*i;
                    inport_name = strcat(convertSys, filesep, 'In',num2str(i));
                    add_block('simulink/Ports & Subsystems/In1',...
                        inport_name,...
                        'MakeNameUnique', 'on', ...
                        'Position',[x y (x+30) (y+20)]);
                    if ~strcmp(InportsDTs{i}, 'double')
                        convBlkName = strcat(convertSys, filesep, 'convert', num2str(i));
                        add_block('simulink/Signal Attributes/Data Type Conversion',convBlkName, ...
                            'Position', [(x + 50) (y - 15) (x + 100) (y+35)],...
                            'OutDataTypeStr', InportsDTs{i});
                        add_line(convertSys, ...
                            strcat('In',num2str(i), '/1'), ...
                            strcat('convert', num2str(i), '/1'), ...
                            'autorouting','on');
                    end
                    rateBlkName = strcat(convertSys, filesep, 'rateT', num2str(i));
                    add_block('simulink/Signal Attributes/Rate Transition',rateBlkName, ...
                        'Position', [(x + 150) (y - 15) (x + 200) (y+35)],...
                        'OutPortSampleTime', mat2str(sampleTime));
                    if ~strcmp(InportsDTs{i}, 'double')
                        add_line(convertSys, ...
                            strcat('convert', num2str(i), '/1'), ...
                            strcat('rateT', num2str(i), '/1'), ...
                            'autorouting','on');
                    else
                        add_line(convertSys, ...
                            strcat('In',num2str(i), '/1'), ...
                            strcat('rateT', num2str(i), '/1'), ...
                            'autorouting','on');
                    end
                    
                    outport_name = strcat(convertSys, filesep, 'Out',num2str(i));
                    add_block('simulink/Ports & Subsystems/Out1',...
                        outport_name,...
                        'MakeNameUnique', 'on', ...
                        'Position', [(x + 300) y (x + 330) (y+20)]);
                    add_line(convertSys, ...
                        strcat('rateT', num2str(i), '/1'), ...
                        strcat('Out',num2str(i), '/1'), ...
                        'autorouting','on');
                    
                    %link conversion subsystem to model subsystem.
                    add_line(newBaseName, ...
                        strcat('Converssion', '/', num2str(i)), ...
                        strcat(subsys_name, '/', num2str(i)), ...
                        'autorouting','on');
                    
                end
                % add signal builder signal
                try
                    % for tests with one step should be adapted
                    for i=1:numel(T)
                        if numel(T(i).time) == 1
                            T(i).time(2) = sampleTime(1);
                            for j=1:numel( T(i).signals)
                                T(i).signals(j).values(2) = T(i).signals(j).values(1);
                            end
                        end
                    end
                    signalBuilderName = fullfile(newBaseName, 'Inputs');
                    signalbuilder(signalBuilderName, 'create', T(1).time, arrayfun(@(x) {double(x.values)}, T(1).signals)');
                    stopTime = T(1).time(end) + 0.0000000000001;
                    for i=2:numel(T)
                        try
                            signalbuilder(signalBuilderName, 'appendgroup', T(i).time, arrayfun(@(x) {double(x.values)}, T(i).signals)');
                            if T(i).time(end) > stopTime
                                stopTime = T(i).time(end) + 0.0000000000001;
                            end
                        catch me
                            display_msg(me.getReport(), MsgType.DEBUG, 'makeharness', '');
                        end
                    end
                    set_param(signalBuilderName, 'Position', [50    50   210   (50+30*m)]);
                    
                    for i=1:nb_inports
                        add_line(newBaseName, ...
                            strcat('Inputs', '/', num2str(i)), ...
                            strcat('Converssion', '/', num2str(i)), ...
                            'autorouting','on');
                        
                    end
                    
                    configSet = getActiveConfigSet(newBaseName);
                    set_param(configSet, 'SaveFormat', 'Structure', ...
                        'StopTime', num2str(stopTime), ...
                        'Solver', 'FixedStepDiscrete', ...
                        'FixedStep', num2str(sampleTime(1)));
                    save_system(newBaseName, new_model_name,'OverwriteIfChangedOnDisk',true);
                    display_msg(['Generated harness model is in: ' new_model_name],...
                        MsgType.RESULT, 'makeharness', '');
                    open(new_model_name)
                catch me
                    display_msg('Test cases struct is not well formed.', MsgType.ERROR, 'makeharness', '');
                    display_msg(me.message, MsgType.ERROR, 'makeharness', '');
                    display_msg(me.getReport(), MsgType.DEBUG, 'makeharness', '');
                    status = 1;
                end
                
            catch me
                display_msg('Failed generating harness model.', MsgType.ERROR, 'makeharness', '');
                display_msg(me.message, MsgType.ERROR, 'makeharness', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'makeharness', '');
                status = 1;
            end
        end
        
        function U_dims = tf_get_U_dims(model, pp_name, blkList)            
            %% geting dimensions of U 
            warning off;
            code_on=sprintf('%s([], [], [], ''compile'')', model);
            eval(code_on);
            try
                U_dims = {};
                for i=1:length(blkList)
                    CompiledPortDimensions = get_param(blkList{i}, 'CompiledPortDimensions');
                    in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(CompiledPortDimensions.Inport);
                    if numel(in_matrix_dimension) > 1
                        display_msg(sprintf('block %s has external numerator/denominator not supported',...
                            blkList{i}), ...
                            MsgType.ERROR, pp_name, '');
                        U_dims{end+1} = [];
                        continue;
                    else
                        U_dims{end+1} = in_matrix_dimension{1}.dims;
                    end
                end
            catch me
                display_msg(me.getReport(), ...
                    MsgType.DEBUG, pp_name, '');
                code_off = sprintf('%s([], [], [], ''term'')', model);
                eval(code_off);
                warning on;
                return;
            end
            code_off = sprintf('%s([], [], [], ''term'')', model);
            eval(code_off);
            warning on;
            
        end
    end
    
end

