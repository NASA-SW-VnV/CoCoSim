classdef SLXUtils
    %SLXUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        %% Try to calculate Block sample time using GCD
        function st = get_BlockDiagram_SampleTime(file_name)
            warning off;
            ts = Simulink.BlockDiagram.getSampleTimes(file_name);
            warning on;
            st = 1;
            for t=ts
                if ~isempty(t.Value) && isnumeric(t.Value)
                    tv = t.Value(1);
                    if ~(isnan(tv) || tv==Inf)
                        st = gcd(st*100,tv*100)/100;
                        
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
                IMAX = 100;
            end
            if ~exist('IMIN', 'var')
                IMIN = -100;
            end
            numberOfInports = numel(inports);
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
        
    end
    
end

