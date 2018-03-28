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
        function isEnabled = isEnabledStr()
            isEnabled = '_isEnabled';
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
                [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys.Content.(Portsfields{i}));
                names = [names, names_i];
                names_withNoDT = [names_withNoDT, names_withNoDT_i];
            end
            if strcmp(type, 'Inport')
                % add enable port to the node inputs, its value may be used
                enablePortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
                if ~isempty(enablePortsFields) ...
                        && strcmp(subsys.Content.(enablePortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys.Content.(enablePortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                end
                % add trigger port to the node inputs, its value may be used
                triggerPortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'TriggerPort'), fields));
                if ~isempty(triggerPortsFields) ...
                        && strcmp(subsys.Content.(triggerPortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys.Content.(triggerPortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                end
            end
            
        end
        
        %% get block outputs names: inlining dimension
        function [names, names_dt] = getBlockOutputsNames(blk, srcPort)
            % This function return the names of the block
            % outputs.
            % Example : an Inport In with dimension [2, 3] will be
            % translated as : In_1, In_2, In_3, In_4, In_5, In_6.
            % where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),        
            % In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
            % A block is defined by its outputs, if a block does not
            % have outports, like Outport block, than will be defined by its
            % inports. E.g, Outport Out with width 2 -> Out_1, out_2
            
            if isempty(blk.CompiledPortWidths.Outport)
                width = blk.CompiledPortWidths.Inport;
                type = 'Outport';
            else
                width = blk.CompiledPortWidths.Outport;
                type = 'Inport';
            end
            
            names = {};
            names_dt = {};
            if nargin >= 2 && ~isempty(srcPort)
                port = srcPort + 1;% srcPort starts by zero
                if strcmp(type, 'Outport')
                    dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(port));
                else
                    dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(port));
                end
                % The width should start from the port width regarding all
                % subsystem outputs
                idx = sum(width(1:port-1))+1;
                for i=1:width(port)
                    names{i} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx)));
                    names_dt{i} = strcat(names{i} , ': ', dt, ';');
                    idx = idx + 1;
                end
            else
                idx = 1;
                for port=1:numel(width)
                    if strcmp(type, 'Outport')
                        dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(port));
                    else
                        dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(port));
                    end
                    for i=1:width(port)
                        names{idx} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx)));
                        names_dt{idx} = strcat(names{idx} , ': ', dt, ';');
                        idx = idx + 1;
                    end
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
                n_i = SLX2LusUtils.getBlockOutputsNames(src, srcPort);
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
                n_i = SLX2LusUtils.getBlockOutputsNames(src, srcPort);
                inputs = [inputs, n_i];
            end
        end
        %% get pre block for specific port number
        function [src] = getpreBlock(parent, blk, Port)
            srcBlks = blk.PortConnectivity(...
                arrayfun(@(x) ~isempty(x.SrcBlock), blk.PortConnectivity));
            srcBlks = srcBlks(Port);
            srcPort = srcBlks.SrcPort;
            srcHandle = srcBlks.SrcBlock;
            src = get_struct(parent, srcHandle);
        end
        %% Change Simulink DataTypes to Lustre DataTypes. Initial default
        %value is also given as a string.
        function [ Lustre_type, zero, one ] = get_lustre_dt( slx_dt)
            if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
                Lustre_type = slx_dt;
            else
                if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean')
                    Lustre_type = 'bool';
                elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
                    Lustre_type = 'int';
                else
                    Lustre_type = 'real';
                end
            end
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
        
        %% Data type conversion node name
        function [external_lib, conv_format] = dataType_conversion(inport_dt, outport_dt, RndMeth)
            lus_in_dt = SLX2LusUtils.get_lustre_dt( inport_dt);
            if nargin < 3
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
                case {'int8','uint8','int16','uint16'}
                    
                    conv = strcat('int_to_', outport_dt);
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
                case {'int32','uint32'}
                    % supporting 'int32','uint32' as lustre int.
                    if strcmp(lus_in_dt, 'bool')
                        external_lib = {'bool_to_int'};
                        conv_format = 'bool_to_int(%s)';
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {RndMeth};
                        conv_format = strcat(RndMeth, '(%s)');
                    end
                    
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
                    'false -> %s and not pre %s'...
                    ,b ,b );
            elseif strcmp(resetType, 'Falling') || strcmp(resetType, 'falling')
                resetCode = sprintf(...
                    'false -> not %s and pre %s'...
                    ,b ,b);
            elseif strcmp(resetType, 'Either') || strcmp(resetType, 'either')
                resetCode = sprintf(...
                    'false -> (%s and not pre %s) or (not %s and pre %s) '...
                    ,b ,b ,b ,b);
            else
                resetCode = '';
                status = 1;
                return;
            end
        end
        
        %% trigger value
        function TriggerinputExp = getTriggerValue(Cond, triggerInput, TriggerType, dt)
            if strcmp(dt, 'real')
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
                    'rising', dt, triggerInput, zero );
                TriggerinputExp = sprintf(...
                    '%s -> if %s then if %s then 1%s else -1%s else 0%s'...
                    ,zero,  Cond, risingCond, suffix, suffix, suffix);
            end
        end
    end
    
end

