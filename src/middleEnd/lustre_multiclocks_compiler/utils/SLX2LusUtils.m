classdef SLX2LusUtils < handle
    %LUS2UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
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
        function result = extract_node_InOutputs_withDT(subsys, type, xml_trace)
            result = {};
            %get all blocks names
            fields = fieldnames(subsys.Content);
            
            % remove blocks without BlockType (e.g annotations)
            fields = ...
                fields(...
                cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
            
            % get only blocks with BlockType=type
            fields = ...
                fields(...
                cellfun(@(x) strcmp(subsys.Content.(x).BlockType,type), fields));
            
            % sort the blocks by order of their ports
            ports = cellfun(@(x) str2num(subsys.Content.(x).Port), fields);
            [~, I] = sort(ports);
            fields = fields(I);
            names = {};
            for i=1:numel(fields)
                [~, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys.Content.(fields{i}));
                names = [names, names_i];
            end
            
            result = MatlabUtils.strjoin(names, ';\n');
        end
        
        %% get Inport/Outport names: inlining dimension
        function [names, names_dt] = getBlockOutputsNames(blk)
            % This function return the names of the block
            % outputs. 
            % Example : an Inport In with dimensio [1, 2] will be
            % translated as : In_1, In_2.
            % A block is defined by its outputs, if a block the does not
            % have outports, like Outport block, than will be defined by its
            % inports. E.g, Outport Out with dimension 2 -> Out_1, out2

            if isempty(blk.CompiledPortWidths.Outport)
                width = blk.CompiledPortWidths.Inport;
                type = 'Outport';
            else
                width = blk.CompiledPortWidths.Outport;
                type = 'Inport';
            end
            
            names = {};
            names_dt = {};
            for port=1:numel(width)
                if strcmp(type, 'Outport')
                    dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(port));
                else
                    dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(port));
                end
                for i=1:width(port)
                    names{numel(names) + 1} = SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(i)));
                    names_dt{numel(names_dt) + 1} = strcat(names{i} , ': ', dt);
                end
            end
            
        end
        
        %% Change Simulink DataTypes to Lustre DataTypes. Initial default 
        %value is also given as a string.
        function [ Lustre_type, initial_value ] = get_lustre_dt( slx_dt)
            if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
                Lustre_type = slx_dt;
            else
                if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean')
                    Lustre_type = 'bool';
                    initial_value = 'false';
                elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
                    Lustre_type = 'int';
                    initial_value = '0';
                else
                    Lustre_type = 'real';
                    initial_value = '0.0';
                end
            end
        end
    end
    
end

