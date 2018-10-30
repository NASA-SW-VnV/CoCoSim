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
                %warning on;
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
        function [Value, valueDataType, status] = evalParam(modelObj, parent, blk, param)
            % This function should work with IR structure extracted from
            % the Simulink model and used in ToLustre compiler.
            % It can be used with char parameters as well. We change them
            % to objects
            status = 0;
            valueDataType = 'double';
            Value = 0;
            try
                if ischar(modelObj)
                    modelObj = get_param(modelObj, 'Object');
                end
                if ischar(parent)
                    parent = get_param(parent, 'Object');
                end
                if ischar(blk)
                    blk = get_param(blk, 'Object');
                end
                if isempty(regexp(param, '[a-zA-Z]', 'match'))
                    % do not use str2double
                    Value = str2num(param);
                    if contains(param, '.')
                        valueDataType = 'double';
                    else
                        valueDataType = 'int';
                    end
                elseif strcmp(param, 'true') ...
                        ||strcmp(param, 'false')
                    Value = evalin('base', param);
                    valueDataType = 'boolean';
                else
                    % this is the case of variable from model workspace
                    hws = modelObj.ModelWorkspace ;
                    if isvarname(param) && hasVariable(hws, param)
                        Value = getVariable(hws, param);
                    else
                        try
                            try
                                %if it is not a mask parameter, it will
                                %launch an exception.
                                new_param = parent.(param);
                                new_parent = get_param(parent.Handle, 'Parent');
                                [Value, valueDataType, status] = ...
                                    SLXUtils.evalParam(...
                                    modelObj, ...
                                    new_parent, ...
                                    parent,...
                                    new_param);
                                if status
                                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                        new_param, parent), ...
                                        MsgType.ERROR, 'SLXUtils.evalParam', '');
                                    return;
                                end
                                return;
                            catch
                                % It is not a mask parameter
                            end
                            Value = evalin('base', param);
                            if ischar(Value)
                                [Value, valueDataType, status] = ...
                                    SLXUtils.evalParam(modelObj, parent, blk, Value);
                                return;
                            end
                            valueDataType =  class(Value);
                        catch me
                            if isequal(me.identifier, 'MATLAB:UndefinedFunction')
                                % Case of e.g. param = 2*f and f is a mask parameter
                                tokens = ...
                                    regexp(me.message, '''(\w+)''', 'tokens', 'once');
                                if ~isempty(tokens)
                                    f = tokens{1};
                                    try
                                        %if it is not a mask parameter, it will
                                        %launch an exception.
                                        new_param = parent.(f);
                                        new_parent = get_param(parent.Handle, 'Parent');
                                        [f_v, ~, status] = ...
                                            SLXUtils.evalParam(...
                                            modelObj, ...
                                            new_parent, ...
                                            parent,...
                                            new_param);
                                        if status
                                            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                                new_param, parent), ...
                                                MsgType.ERROR, 'SLXUtils.evalParam', '');
                                            return;
                                        end
                                        % back to the complex param
                                        assignin('base', f, f_v);
                                        [Value, valueDataType, status] = ...
                                            SLXUtils.evalParam(modelObj, parent, blk, param);
                                        evalin('base', sprintf('clear %s', f));
                                        return;
                                    catch
                                    end
                                end
                            end
                            try
                                Value = get_param(parent.Handle, param);
                                Value = evalin('base', Value);
                            catch
                                status = 1;
                            end
                        end
                    end
                end
            catch
                status = 1;
            end
        end
        
        %% Get compiled params: CompiledPortDataTypes ...
        function [res] = getCompiledParam(h, param)
            res = [];
            slx_file_name = get_param(bdroot(h), 'Name');
            code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
            try
                evalin('base',code_on);
                res = get_param(h, param);
                code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
                evalin('base',code_off);
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'getCompiledParam', '');
                code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
                evalin('base',code_off);
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
        
        %% Get percentage of tolerance from floiting values between lustrec and SLX
        function eps = getLustrescSlxEps(model_path)
            [~, model, ~ ] = fileparts(model_path);
            if ~bdIsLoaded(model); load_system(model_path); end
            hws = get_param(model, 'modelworkspace') ;
            if hasVariable(hws,'lustrec_slx_eps')
                eps = getVariable(hws,'lustrec_slx_eps');
            else
                eps = 1e-4;
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
            %warning on;
        end
        
        %% create random vector test
        function [input_struct, ...
                simulation_step, ...
                stop_time] = get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN)
            if nargin < 3
                inputEvents_names = {};
            end
            if nargin < 4
                nb_steps = 100;
            end
            if nargin < 5
                IMAX = 500;
            end
            if nargin < 6
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
                %TODO: To use 'square', the following product must be licensed, installed, and enabled:
                %   Signal Processing Toolbox
%                 if find(strcmp(inputEvents_names,inports(i).name))
%                     input_struct.signals(i).values = square((numberOfInports-i+1)*rand(1)*input_struct.time);
%                     input_struct.signals(i).dimensions = 1;
%                 else
                if strcmp(LusValidateUtils.get_lustre_dt(inports(i).datatype),'bool')
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
            try
                configSet = getActiveConfigSet(slx_file_name);
            catch
                configSet = Simulink.ConfigSet;
            end
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
                %warning on;
            else
                if show_models
                    open(slx_file_name)
                end
                warning off;
                simOut = sim(slx_file_name, configSet);
                %warning on;
            end
        end
        
        %%
        function [new_model_path, new_model_name, status] = crete_model_from_subsystem(file_name, ss_path, output_dir )
            block_name_adapted = BUtils.adapt_block_name(MatlabUtils.naming(LusValidateUtils.name_format(ss_path)));
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
            blk_name = get_param(ss_path, 'Name');
            new_blkH = add_block(ss_path, ...
                strcat(new_model_name, '/', blk_name));
            newBlokPortHandles = get_param(new_blkH, 'PortHandles');
            %Inports
            status = 0;
            for i=1:numel(newBlokPortHandles.Enable)
                status = status + addInport(newBlokPortHandles.Enable(i));
            end
            for i=1:numel(newBlokPortHandles.Ifaction)
                status = status + addInport(newBlokPortHandles.Ifaction(i));
            end
            for i=1:numel(newBlokPortHandles.Inport)
                status = status + addInport(newBlokPortHandles.Inport(i));
            end
            for i=1:numel(newBlokPortHandles.Reset)
                status = status + addInport(newBlokPortHandles.Reset(i));
            end
            for i=1:numel(newBlokPortHandles.Trigger)
                status = status + addInport(newBlokPortHandles.Trigger(i));
            end
            %Outport
            for i=1:numel(newBlokPortHandles.Outport)
                status = status + addOutport(newBlokPortHandles.Outport(i));
            end
            try
                BlocksPosition_pp(new_model_path, 1);
            catch
            end
            %% Save system
            save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);
            function status = addInport(newBlkPort)
                try
                    status = 0;
                    inport_name = fullfile(new_model_name, 'In1');
                    inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                        inport_name,...
                        'MakeNameUnique', 'on');
                    inportPortHandles = get_param(inport_handle, 'PortHandles');
                    add_line(new_model_name,...
                        inportPortHandles.Outport(1), newBlkPort,...
                        'autorouting', 'on');
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                    status = 1;
                end
            end
            function status = addOutport(newBlkPort)
                try
                    status = 0;
                    outport_name = fullfile(new_model_name, 'Out1');
                    outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                        outport_name,...
                        'MakeNameUnique', 'on');
                    outportPortHandles = get_param(outport_handle, 'PortHandles');
                    add_line(new_model_name,...
                        newBlkPort, outportPortHandles.Inport(1),...
                        'autorouting', 'on');
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                    status = 1;
                end
            end
            
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
        
        %%
        function U_dims = tf_get_U_dims(model, pp_name, blkList)
            % geting dimensions of U
            warning off;
            code_on=sprintf('%s([], [], [], ''compile'')', model);
            eval(code_on);
            try
                U_dims = cell(1, length(blkList));
                for i=1:length(blkList)
                    try
                        NumeratorSource = get_param(blkList{i}, 'NumeratorSource');
                        DenominatorSource = get_param(blkList{i}, 'DenominatorSource');
                    catch
                        NumeratorSource = '';
                        DenominatorSource = '';
                    end
                    
                    if isequal(NumeratorSource, 'Input port') ...
                            || isequal(DenominatorSource, 'Input port')
                        display_msg(sprintf('block %s has external numerator/denominator not supported',...
                            blkList{i}), ...
                            MsgType.ERROR, pp_name, '');
                        U_dims{i} = [];
                        continue;
                    end
                    CompiledPortDimensions = get_param(blkList{i}, 'CompiledPortDimensions');
                    in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(CompiledPortDimensions.Inport);
                    if numel(in_matrix_dimension) > 1
                        display_msg(sprintf('block %s has external reset signal not supported',...
                            blkList{i}), ...
                            MsgType.ERROR, pp_name, '');
                        U_dims{i} = [];
                        continue;
                    else
                        U_dims{i} = in_matrix_dimension{1}.dims;
                    end
                end
            catch me
                display_msg(me.getReport(), ...
                    MsgType.DEBUG, pp_name, '');
                code_off = sprintf('%s([], [], [], ''term'')', model);
                eval(code_off);
                %warning on;
                return;
            end
            code_off = sprintf('%s([], [], [], ''term'')', model);
            eval(code_off);
            %warning on;
            
        end
        
        %%
        function status = createSubsystemFromBlk(blk_path)
            status = 0;
            try
                blk_name = get_param(blk_path, 'Name');
                try
                    % localCreateSubSystem function only exists in newer
                    % versions of Matlab
                    h = get_param(blk_path, 'Handle');
                    blkHandles = get_param(h, 'PortHandles');
                    if numel(blkHandles.Outport) > 0
                        l = get_param(blkHandles.Outport(1), 'line');
                        dst_port_Handles = get_param(l, 'DstPortHandle');
                        dstPortHandle = dst_port_Handles(1);
                    else
                        l = -1;
                    end
                    obj = get_param( bdroot(blk_path), 'Object');
                    obj.localCreateSubSystem(h);
                    
                    %change name of Subsystem created to match the original
                    %block name
                    if l == -1
                        return;
                    end
                    l = get_param(dstPortHandle, 'line');
                    srcPortH = get_param(l, 'SrcPortHandle');
                    subsystemPath = get_param(srcPortH, 'Parent');
                    set_param(subsystemPath, 'Name', blk_name);
                    return;
                catch
                    %we will do it manually
                end
                % No need for this function in R2017b. But we do it for R2015b
                blokPortHandles = get_param(blk_path, 'PortHandles');
                parent = get_param(blk_path, 'Parent');
                ss_path = fullfile(parent, strcat(blk_name,'_tmp'));
                ss_handle = add_block('built-in/Subsystem',ss_path,...
                    'MakeNameUnique', 'on');
                Simulink.ModelReference.DeleteContent.deleteContents(ss_handle);
                % make sure the name did not change
                ss_path = fullfile(parent, get_param(ss_handle, 'Name'));
                blk_new_path = fullfile(ss_path, blk_name);
                add_block(blk_path, blk_new_path);
                newBlokPortHandles = get_param(blk_new_path, 'PortHandles');
                %Inports
                for i=1:numel(newBlokPortHandles.Enable)
                    status = status + addInport(newBlokPortHandles.Enable(i), blokPortHandles.Enable(i));
                end
                for i=1:numel(newBlokPortHandles.Ifaction)
                    status = status + addInport(newBlokPortHandles.Ifaction(i), blokPortHandles.Ifaction(i));
                end
                for i=1:numel(newBlokPortHandles.Inport)
                    status = status + addInport(newBlokPortHandles.Inport(i), blokPortHandles.Inport(i));
                end
                for i=1:numel(newBlokPortHandles.Reset)
                    status = status + addInport(newBlokPortHandles.Reset(i), blokPortHandles.Reset(i));
                end
                for i=1:numel(newBlokPortHandles.Trigger)
                    status = status + addInport(newBlokPortHandles.Trigger(i), blokPortHandles.Trigger(i));
                end
                %Outport
                for i=1:numel(newBlokPortHandles.Outport)
                    status = status + addOutport(newBlokPortHandles.Outport(i), blokPortHandles.Outport(i));
                end
                
                if status
                    return;
                end
                orient=get_param(blk_path,'orientation');
                pos=get_param(blk_path,'position');
                delete_block(blk_path);
                BlocksPosition_pp(ss_path, 0)
                set_param(ss_handle, 'orientation', orient);
                set_param(ss_handle, 'position', pos);
                set_param(ss_handle, 'Name', blk_name);
            catch me
                display_msg(me.getReport(), ...
                    MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                status = 1;
            end
            % nested functions
            function status = addInport(newBlkPort, origBlkPort)
                try
                    status = 0;
                    inport_name = fullfile(ss_path, 'In1');
                    inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                        inport_name,...
                        'MakeNameUnique', 'on');
                    inportPortHandles = get_param(inport_handle, 'PortHandles');
                    add_line(ss_path,...
                        inportPortHandles.Outport(1), newBlkPort,...
                        'autorouting', 'on');
                    %this line is important to update ssBlockHandles
                    ssBlockHandles = get_param(ss_path, 'PortHandles');
                    line = get_param(origBlkPort, 'line');
                    if line == -1
                        % no connected line
                        return;
                    end
                    srcPortHandle = get_param(line, 'SrcPortHandle');
                    delete_line(line);
                    add_line(parent,...
                        srcPortHandle, ssBlockHandles.Inport(end),...
                        'autorouting', 'on');
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                    status = 1;
                end
            end
            function status = addOutport(newBlkPort, origBlkPort)
                try
                    status = 0;
                    outport_name = fullfile(ss_path, 'Out1');
                    outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                        outport_name,...
                        'MakeNameUnique', 'on');
                    outportPortHandles = get_param(outport_handle, 'PortHandles');
                    add_line(ss_path,...
                        newBlkPort, outportPortHandles.Inport(1),...
                        'autorouting', 'on');
                    %this line is important to update ssBlockHandles
                    ssBlockHandles = get_param(ss_path, 'PortHandles');
                    line = get_param(origBlkPort, 'line');
                    if line == -1
                        % no connected line
                        return;
                    end
                    dstPortHandles = get_param(line, 'DstPortHandle');
                    delete_line(line);
                    for d=dstPortHandles'
                        add_line(parent,...
                            ssBlockHandles.Outport(end), d,...
                            'autorouting', 'on');
                    end
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                    status = 1;
                end
            end
        end
        
    end
    
end

