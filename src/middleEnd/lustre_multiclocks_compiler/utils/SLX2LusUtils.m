classdef SLX2LusUtils < handle
    %LUS2UTILS contains all functions that helps in the translation from
    %Simulink to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods (Static = true)
        %% refactoring names
        function isEnabled = isEnabledStr()
            isEnabled = '_isEnabled';
        end
        function isEnabled = isTriggeredStr()
            isEnabled = '_isTriggered';
        end
        function time_step = timeStepStr()
            time_step = '__time_step';
        end
        %% adapt blocks names to be a valid lustre names.
        function str_out = name_format(str)
            newline = sprintf('\n');
            str_out = strrep(str, newline, '');
            str_out = strrep(str_out, ' ', '');
            str_out = strrep(str_out, '-', '_minus_');
            str_out = strrep(str_out, '+', '_plus_');
            str_out = strrep(str_out, '*', '_mult_');
            str_out = strrep(str_out, '.', '_dot_');
            str_out = strrep(str_out, '#', '_sharp_');
            str_out = strrep(str_out, '(', '_lpar_');
            str_out = strrep(str_out, ')', '_rpar_');
            str_out = strrep(str_out, '[', '_lsbrak_');
            str_out = strrep(str_out, ']', '_rsbrak_');
            str_out = strrep(str_out, '{', '_lbrak_');
            str_out = strrep(str_out, '}', '_rbrak_');
            str_out = strrep(str_out, ',', '_comma_');
            %             str_out = strrep(str_out, '/', '_slash_');
            str_out = strrep(str_out, '=', '_equal_');
            % for blocks starting with a digit.
            str_out = regexprep(str_out, '^(\d+)', 'x$1');
            str_out = regexprep(str_out, '/(\d+)', '/_$1');
            % for anything missing from previous cases.
            str_out = regexprep(str_out, '[^a-zA-Z0-9_/]', '_');
        end
        
        
        %% Lustre node name from a simulink block name. Here we choose only
        %the name of the block concatenated to its handle to be unique
        %name.
        function node_name = node_name_format(subsys_struct)
            if isempty(strfind(subsys_struct.Path, filesep))
                % main node: should be the same as filename
                node_name = SLX2LusUtils.name_format(subsys_struct.Name);
            else
                handle_str = strrep(sprintf('%.3f', subsys_struct.Handle), '.', '_');
                node_name = sprintf('%s_%s',SLX2LusUtils.name_format(subsys_struct.Name),handle_str );
            end
        end
        
        %% Lustre node inputs, outputs
        function [node_name, node_inputs, node_outputs, ...
                node_inputs_withoutDT, node_outputs_withoutDT ] = ...
                extractNodeHeader(blk, is_main_node, isEnableORAction, isEnableAndTrigger, main_sampleTime, xml_trace)
            % creating node header
            node_name = SLX2LusUtils.node_name_format(blk);
            [node_inputs_cell, node_inputs_withoutDT_cell] = ...
                SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Inport', xml_trace);
            node_inputs = MatlabUtils.strjoin(node_inputs_cell, '\n');
            if isEnableORAction
                node_inputs = [node_inputs, ...
                    strcat(SLX2LusUtils.isEnabledStr() , ':bool;')];
            elseif isEnableAndTrigger
                node_inputs = sprintf('%s%s,%s:bool;',node_inputs, ...
                    SLX2LusUtils.isEnabledStr(), SLX2LusUtils.isTriggeredStr() );
            end
            if ~is_main_node
                node_inputs = [node_inputs, sprintf('%s:real;', SLX2LusUtils.timeStepStr())];
                node_inputs_withoutDT_cell{end+1} = ...
                    sprintf('%s', SLX2LusUtils.timeStepStr());
                % add clocks
                clocks_list = SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
                if ~isempty(clocks_list)
                    node_inputs = [node_inputs, sprintf('%s:bool clock;', clocks_list)];
                    node_inputs_withoutDT_cell{end+1} = sprintf('%s', clocks_list);
                end
            end
            if isempty(node_inputs)
                node_inputs = '_virtual:bool;';
                node_inputs_withoutDT_cell{end+1} = '_virtual';
            end
            node_inputs_withoutDT = ...
                MatlabUtils.strjoin(node_inputs_withoutDT_cell, ',\n\t\t');
            [node_outputs_cell, node_outputs_withoutDT_cell] = SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Outport', xml_trace);
            node_outputs = MatlabUtils.strjoin(node_outputs_cell, '\n');
            node_outputs_withoutDT = ...
                MatlabUtils.strjoin(node_outputs_withoutDT_cell, ',\n\t\t');
            if is_main_node && isempty(node_outputs)
                node_outputs = sprintf('%s:real;', SLX2LusUtils.timeStepStr());
            end
        end
        function [names, names_withNoDT] = extract_node_InOutputs_withDT(subsys, type, xml_trace)
            %get all blocks names
            fields = fieldnames(subsys.Content);
            
            % remove blocks without BlockType (e.g annotations)
            fields = ...
                fields(...
                cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
            
            % get only blocks with BlockType=type
            Portsfields = ...
                fields(...
                cellfun(@(x) strcmp(subsys.Content.(x).BlockType,type), fields));
            
            
            % sort the blocks by order of their ports
            ports = cellfun(@(x) str2num(subsys.Content.(x).Port), Portsfields);
            [~, I] = sort(ports);
            Portsfields = Portsfields(I);
            names = {};
            names_withNoDT = {};
            for i=1:numel(Portsfields)
                [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(Portsfields{i}));
                names = [names, names_i];
                names_withNoDT = [names_withNoDT, names_withNoDT_i];
            end
            if strcmp(type, 'Inport')
                % add enable port to the node inputs, its value may be used
                enablePortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
                if ~isempty(enablePortsFields) ...
                        && strcmp(subsys.Content.(enablePortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(enablePortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                end
                % add trigger port to the node inputs, its value may be used
                triggerPortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'TriggerPort'), fields));
                if ~isempty(triggerPortsFields) ...
                        && strcmp(subsys.Content.(triggerPortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(triggerPortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                end
            end
            
        end
        
        %% get block outputs names: inlining dimension
        function [names, names_dt] = getBlockOutputsNames(parent, blk, srcPort)
            % This function return the names of the block
            % outputs.
            % Example : an Inport In with dimension [2, 3] will be
            % translated as : In_1, In_2, In_3, In_4, In_5, In_6.
            % where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),
            % In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
            % A block is defined by its outputs, if a block does not
            % have outports, like Outport block, than will be defined by its
            % inports. E.g, Outport Out with width 2 -> Out_1, out_2
            names = {};
            names_dt = {};
            if isempty(blk) ...
                    || (isempty(blk.CompiledPortWidths.Outport) ...
                    && isempty(blk.CompiledPortWidths.Inport))
                return;
            end
            % case of block with 'auto' Type, we need to get the inports
            % datatypes.
            if numel(blk.CompiledPortDataTypes.Outport) == 1 ...
                    && strcmp(blk.CompiledPortDataTypes.Outport{1}, 'auto') ...
                    && ~isempty(blk.CompiledPortWidths.Inport)
                width = blk.CompiledPortWidths.Inport;
                type = 'Inports';
                
            elseif isempty(blk.CompiledPortWidths.Outport)
                width = blk.CompiledPortWidths.Inport;
                type = 'Inports';
            else
                width = blk.CompiledPortWidths.Outport;
                type = 'Outports';
            end
            
            function [names, names_dt] = blockOutputs(portNumber)
                names = {};
                names_dt = {};
                if strcmp(type, 'Inports')
                    slx_dt = blk.CompiledPortDataTypes.Inport{portNumber};
                else
                    slx_dt = blk.CompiledPortDataTypes.Outport{portNumber};
                end
                if strcmp(slx_dt, 'auto')
                    % this is the case of virtual bus, we need to do back
                    % propagation to find the real datatypes
                    lus_dt = SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                    isBus = false;
                else
                    [lus_dt, ~, ~, isBus] = SLX2LusUtils.get_lustre_dt(slx_dt);
                end
                % The width should start from the port width regarding all
                % subsystem outputs
                idx = sum(width(1:portNumber-1))+1;
                for i=1:width(portNumber)
                    if isBus
                        for k=1:numel(lus_dt)
                            names{end+1} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx), '_BusElem', num2str(k)));
                            names_dt{end+1} = strcat(names{end} , ': ', lus_dt{k}, ';');
                        end
                    elseif iscell(lus_dt) && numel(lus_dt) == width(portNumber)
                        names{end+1} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx)));
                        names_dt{end+1} = sprintf('%s: %s;', names{end}, char(lus_dt{i}));
                    else
                        names{end+1} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx)));
                        names_dt{end+1} = sprintf('%s: %s;', names{end}, char(lus_dt));
                    end
                    idx = idx + 1;
                end
            end
            if nargin >= 3 && ~isempty(srcPort)...
                    && ~strcmp(blk.CompiledPortDataTypes.Outport{srcPort + 1}, 'auto')
                port = srcPort + 1;% srcPort starts by zero
                [names, names_dt] = blockOutputs(port);
            else
                for port=1:numel(width)
                    [names_i, names_dt_i] = blockOutputs(port);
                    names = [names, names_i];
                    names_dt = [names_dt, names_dt_i];
                end
            end
        end
        
        %% get block inputs names. E.g subsystem taking input signals from differents blocks.
        % We need to go over all linked blocks and get their output names
        % in the corresponding port number.
        % Read PortConnectivity documentation for more information.
        function [inputs] = getBlockInputsNames(parent, blk, Port)
            % get only inports, we don't take enable/reset/trigger, outputs
            % ports.
            srcPorts = blk.PortConnectivity(...
                arrayfun(@(x) ~isempty(x.SrcBlock) ...
                &&  ~isempty(str2num(x.Type)) , blk.PortConnectivity));
            if nargin >= 3 && ~isempty(Port)
                srcPorts = srcPorts(Port);
            end
            inputs = {};
            for b=srcPorts'
                srcPort = b.SrcPort;
                srcHandle = b.SrcBlock;
                src = get_struct(parent, srcHandle);
                n_i = SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
                inputs = [inputs, n_i];
            end
        end
        function [inputs] = getSubsystemEnableInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'enable');
        end
        function [inputs] = getSubsystemTriggerInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'trigger');
        end
        function [inputs] = getSubsystemResetInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'Reset');
        end
        function [inputs] = getSpecialInputsNames(parent, blk, type)
            srcPorts = blk.PortConnectivity(...
                arrayfun(@(x) strcmp(x.Type, type), blk.PortConnectivity));
            inputs = {};
            for b=srcPorts'
                srcPort = b.SrcPort;
                srcHandle = b.SrcBlock;
                src = get_struct(parent, srcHandle);
                n_i = SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
                inputs = [inputs, n_i];
            end
        end
        %% get pre block for specific port number
        function [src, srcPort] = getpreBlock(parent, blk, Port)
            
            if ischar(Port)
                % case of Type: ifaction ...
                srcBlk = blk.PortConnectivity(...
                    arrayfun(@(x) strcmp(x.Type, Port), blk.PortConnectivity));
            else
                srcBlks = blk.PortConnectivity(...
                    arrayfun(@(x) ~isempty(x.SrcBlock), blk.PortConnectivity));
                srcBlk = srcBlks(Port);
            end
            if isempty(srcBlk)
                src = [];
                srcPort = [];
            else
                % Simulink srcPort starts from 0, we add one.
                srcPort = srcBlk.SrcPort + 1;
                srcHandle = srcBlk.SrcBlock;
                src = get_struct(parent, srcHandle);
            end
        end
        %% get pre block DataType for specific port,
        %it is used in the case of 'auto' type.
        function lus_dt = getpreBlockLusDT(parent, blk, portNumber)
            lus_dt = {};
            if strcmp(blk.BlockType, 'Inport')
                global model_struct
                if ~isempty(model_struct)
                    portNumber = str2num(blk.Port);
                    blk = parent;
                    parent = model_struct;
                end
            end
            [srcBlk, blkOutportPort] = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
            
            if isempty(srcBlk) ...
                    || ~strcmp(srcBlk.BlockType, 'BusCreator')
                lus_dt = {'real'};
                display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                    srcBlk.Origin_path), MsgType.ERROR, '', '');
                return;
            end
            if strcmp(srcBlk.CompiledPortDataTypes.Outport{blkOutportPort}, 'auto')
                width = srcBlk.CompiledPortWidths.Inport;
                for port=1:numel(width)
                    slx_dt = srcBlk.CompiledPortDataTypes.Inport{port};
                    if strcmp(slx_dt, 'auto')
                        lus_dt = [lus_dt, ...
                            SLX2LusUtils.getpreBlockLusDT(parent, srcBlk, port)];
                    else
                        lus_dt_tmp = SLX2LusUtils.get_lustre_dt(slx_dt);
                        if iscell(lus_dt_tmp)
                            lus_dt = [lus_dt, lus_dt_tmp];
                        else
                            lus_dt_tmp = arrayfun(@(x) {lus_dt_tmp}, (1:width(port)), 'UniformOutput',false);
                            lus_dt = [lus_dt, lus_dt_tmp];
                        end
                    end
                end
            else
                width = srcBlk.CompiledPortWidths.Outport;
                slx_dt = srcBlk.CompiledPortDataTypes.Outport{blkOutportPort};
                lus_dt_tmp = SLX2LusUtils.get_lustre_dt(slx_dt);
                if iscell(lus_dt_tmp)
                    lus_dt = [lus_dt, lus_dt_tmp];
                else
                    lus_dt_tmp = cellfun(@(x) {lus_dt_tmp}, (1:width(blkOutportPort)), 'UniformOutput',false);
                    lus_dt = [lus_dt, lus_dt_tmp];
                end
            end
        end
        %% Change Simulink DataTypes to Lustre DataTypes. Initial default
        %value is also given as a string.
        function [ Lustre_type, zero, one, isBus ] = get_lustre_dt( slx_dt)
            isBus = false;
            if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
                Lustre_type = slx_dt;
            else
                if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean') || strcmp(slx_dt, 'action')
                    Lustre_type = 'bool';
                elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
                    Lustre_type = 'int';
                elseif strcmp(slx_dt, 'double') || strcmp(slx_dt, 'single')
                    Lustre_type = 'real';
                else
                    % considering enumaration as int
                    m = evalin('base', sprintf('enumeration(''%s'')',char(slx_dt)));
                    if isempty(m)
                        try
                            isBus = evalin('base', sprintf('isa(%s, ''Simulink.Bus'')',char(slx_dt)));
                        catch
                            isBus = false;
                        end
                        if isBus
                            Lustre_type = SLX2LusUtils.getLustreTypesFromBusObject(char(slx_dt));
                        else
                            Lustre_type = 'real';
                        end
                    else
                        % considering enumaration as int
                        Lustre_type = 'int';
                    end
                    
                end
            end
            if iscell(Lustre_type)
                zero = {};
                one = {};
                for i=1:numel(Lustre_type)
                    if strcmp(Lustre_type{i}, 'bool')
                        zero{i} = 'false';
                        one{i} = 'true';
                    elseif strcmp(Lustre_type{i}, 'int')
                        zero{i} = '0';
                        one{i} = '1';
                    else
                        zero{i} = '0.0';
                        one{i} = '1.0';
                    end
                end
            else
                if strcmp(Lustre_type, 'bool')
                    zero = 'false';
                    one = 'true';
                elseif strcmp(Lustre_type, 'int')
                    zero = '0';
                    one = '1';
                else
                    zero = '0.0';
                    one = '1.0';
                end
            end
        end
        
        %% Bus signal Lustre dataType
        function lustreTypes = getLustreTypesFromBusObject(busName)
            bus = evalin('base', char(busName));
            lustreTypes = {};
            try
                elems = bus.Elements;
            catch
                % Elements is not in bus.
                return;
            end
            for i=1:numel(elems)
                dt = elems(i).DataType;
                dimensions = elems(i).Dimensions;
                width = prod(dimensions);
                if strncmp(dt, 'Bus:', 4)
                    dt = regexprep(dt, 'Bus:\s*', '');
                end
                lusDT = SLX2LusUtils.get_lustre_dt( dt);
                for w=1:width
                    if iscell(lusDT)
                        lustreTypes = [lustreTypes, lusDT];
                    else
                        lustreTypes{end+1} = lusDT;
                    end
                end
            end
        end
        
        function in_matrix_dimension = getDimensionsFromBusObject(busName)
            in_matrix_dimension = {};
            bus = evalin('base', char(busName));
            try
                elems = bus.Elements;
            catch
                % Elements is not in bus.
                return;
            end
            for i=1:numel(elems)
                dt = elems(i).DataType;
                if strncmp(dt, 'Bus:', 4)
                    dt = regexprep(dt, 'Bus:\s*', '');
                    in_matrix_dimension = [in_matrix_dimension,...
                        SLX2LusUtils.getDimensionsFromBusObject(dt)];
                else
                    dimensions = elems(i).Dimensions;
                    idx = numel(in_matrix_dimension) +1;
                    in_matrix_dimension{idx}.dims = dimensions;
                    in_matrix_dimension{idx}.width = prod(dimensions);
                    in_matrix_dimension{idx}.numDs = numel(dimensions);
                end
            end
        end
        
        %% Get the initial ouput of Outport depending on the dimension.
        function InitialOutput_cell = getInitialOutput(parent, blk, InitialOutput, slx_dt, max_width)
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(slx_dt);
            if strcmp(InitialOutput, '[]')
                InitialOutput = '0';
            end
            [InitialOutputValue, InitialOutputType, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
            if status
                display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    InitialOutput, blk.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
                return;
            end
            
            InitialOutput_cell = {};
            for i=1:numel(InitialOutputValue)
                if strcmp(lus_outputDataType, 'real')
                    InitialOutput_cell{i} = sprintf('%.15f', InitialOutputValue(i));
                elseif strcmp(lus_outputDataType, 'int')
                    InitialOutput_cell{i} = sprintf('%d', int32(InitialOutputValue(i)));
                elseif strcmp(lus_outputDataType, 'bool')
                    if InitialOutputValue(i)
                        InitialOutput_cell{i} = 'true';
                    else
                        InitialOutput_cell{i} = 'false';
                    end
                elseif strncmp(InitialOutputType, 'int', 3) ...
                        || strncmp(InitialOutputType, 'uint', 4)
                    InitialOutput_cell{i} = num2str(InitialOutputValue(i));
                elseif strcmp(InitialOutputType, 'boolean') || strcmp(InitialOutputType, 'logical')
                    if InitialOutputValue(i)
                        InitialOutput_cell{i} = 'true';
                    else
                        InitialOutput_cell{i} = 'false';
                    end
                else
                    InitialOutput_cell{i} = sprintf('%.15f', InitialOutputValue(i));
                end
            end
            if numel(InitialOutput_cell) < max_width
                InitialOutput_cell = arrayfun(@(x) {InitialOutput_cell{1}}, (1:max_width));
            end
            
        end
        %% Data type conversion node name
        function [external_lib, conv_format] = dataType_conversion(inport_dt, outport_dt, RndMeth, SaturateOnIntegerOverflow)
            lus_in_dt = SLX2LusUtils.get_lustre_dt( inport_dt);
            if nargin < 3 || isempty(RndMeth)
                if strcmp(lus_in_dt, 'int')
                    RndMeth = 'int_to_real';
                else
                    RndMeth = 'real_to_int';
                end
            else
                if strcmp(lus_in_dt, 'int')
                    RndMeth = 'int_to_real';
                    
                elseif strcmp(RndMeth, 'Simplest') || strcmp(RndMeth, 'Zero')
                    RndMeth = 'real_to_int';
                else
                    RndMeth = strcat('_',RndMeth);
                end
            end
            if nargin < 4 || isempty(SaturateOnIntegerOverflow)
                SaturateOnIntegerOverflow = 'off';
            end
            external_lib = {};
            conv_format = '';
            
            switch outport_dt
                case 'boolean'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {'int_to_bool'};
                        conv_format = 'int_to_bool(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {'real_to_bool'};
                        conv_format = 'real_to_bool(%s)';
                    end
                case {'double', 'single'}
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {RndMeth};
                        conv_format = strcat(RndMeth, '(%s)');
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'bool_to_real'};
                        conv_format = 'bool_to_real(%s)';
                    end
                case {'int8','uint8','int16','uint16', 'int32','uint32'}
                    if strcmp(SaturateOnIntegerOverflow, 'on')
                        conv = strcat('int_to_', outport_dt, '_saturate');
                    else
                        conv = strcat('int_to_', outport_dt);
                    end
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {conv};
                        conv_format = strcat(conv,'(%s)');
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'bool_to_int'};
                        conv_format = 'bool_to_int(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {conv, RndMeth};
                        conv_format = strcat(conv,'(',RndMeth,'(%s))');
                    end
                    % issue should be solved in Lustrec, if lustrec support
                    % int32_t, the following is not important, it is
                    % supported by the previous case (with int16, uint16).
                    %                 case {'int32','uint32'}
                    %                     % supporting 'int32','uint32' as lustre int.
                    %                     if strcmp(lus_in_dt, 'bool')
                    %                         external_lib = {'bool_to_int'};
                    %                         conv_format = 'bool_to_int(%s)';
                    %                     elseif strcmp(lus_in_dt, 'real')
                    %                         external_lib = {RndMeth};
                    %                         conv_format = strcat(RndMeth, '(%s)');
                    %                     end
                    
                case {'fixdt(1,16,0)', 'fixdt(1,16,2^0,0)'}
                    % DataType conversion not supported yet
                    % temporal solution is to consider those types as int
                    if strcmp(lus_in_dt, 'bool')
                        external_lib = { 'bool_to_int'};
                        conv_format = 'bool_to_int(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {RndMeth};
                        conv_format = strcat(RndMeth, '(%s)');
                    end
                    
                    
                    %lustre conversion
                case 'int'
                    if strcmp(lus_in_dt, 'bool')
                        external_lib = {'bool_to_int'};
                        conv_format = 'bool_to_int(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {RndMeth};
                        conv_format = strcat(RndMeth, '(%s)');
                    end
                case 'real'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {RndMeth};
                        conv_format = strcat(RndMeth, '(%s)');
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'bool_to_real'};
                        conv_format = 'bool_to_real(%s)';
                    end
                case 'bool'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {'int_to_bool'};
                        conv_format = 'int_to_bool(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {'real_to_bool'};
                        conv_format = 'real_to_bool(%s)';
                    end
            end
        end
        
        %% reset conditions
        function [resetCode, status] = getResetCode(...
                resetType, resetDT, resetInput, zero )
            status = 0;
            if strcmp(resetDT, 'bool')
                b = sprintf('%s',resetInput);
            else
                b = sprintf('(%s >= %s)',resetInput , zero);
            end
            if strcmp(resetType, 'Rising') || strcmp(resetType, 'rising')
                resetCode = sprintf(...
                    'false -> (%s and not pre %s)'...
                    ,b ,b );
            elseif strcmp(resetType, 'Falling') || strcmp(resetType, 'falling')
                resetCode = sprintf(...
                    'false -> (not %s and pre %s)'...
                    ,b ,b);
            elseif strcmp(resetType, 'Either') || strcmp(resetType, 'either')
                resetCode = sprintf(...
                    'false -> ((%s and not pre %s) or (not %s and pre %s)) '...
                    ,b ,b ,b ,b);
            else
                resetCode = '';
                status = 1;
                return;
            end
        end
        
        %% trigger value
        function TriggerinputExp = getTriggerValue(Cond, triggerInput, TriggerType, TriggerBlockDt, IncomingSignalDT)
            if strcmp(TriggerBlockDt, 'real')
                suffix = '.0';
                zero = '0.0';
            else
                suffix = '';
                zero = '0';
            end
            if strcmp(TriggerType, 'rising')
                TriggerinputExp = sprintf(...
                    '0%s -> if %s then 1%s else 0%s'...
                    ,suffix, Cond, suffix, suffix );
            elseif strcmp(TriggerType, 'falling')
                TriggerinputExp = sprintf(...
                    '0%s -> if %s then -1%s else 0%s'...
                    ,suffix, Cond, suffix, suffix );
            elseif strcmp(TriggerType, 'function-call')
                TriggerinputExp = sprintf(...
                    '0%s -> if %s then 2%s else 0%s'...
                    ,suffix, Cond, suffix, suffix );
            else
                risingCond = SLX2LusUtils.getResetCode(...
                    'rising', IncomingSignalDT, triggerInput, zero );
                TriggerinputExp = sprintf(...
                    '%s -> if %s then if (%s) then 1%s else -1%s else 0%s'...
                    ,zero,  Cond, risingCond, suffix, suffix, suffix);
            end
        end
        
        %% Add clocks of RateTransitions
        function time_step = clockName(st_n, ph_n)
            time_step = sprintf('_clk_%.0f_%.0f', st_n, ph_n);
        end
        function clocks_list = getRTClocksSTR(blk, main_sampleTime)
            clocks_list = '';
            clocks = blk.CompiledSampleTime;
            if iscell(clocks) && numel(clocks) > 1
                c = {};
                for i=1:numel(clocks)
                    T = clocks{i};
                    st_n = T(1)/main_sampleTime(1);
                    ph_n = T(2)/main_sampleTime(1);
                    if ~((st_n == 1 || st_n == 0) && ph_n == 0)
                        c{end+1} = SLX2LusUtils.clockName(st_n, ph_n);
                    end
                end
                clocks_list = MatlabUtils.strjoin(c, ', ');
            end
        end
    end
    
end

