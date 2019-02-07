
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

