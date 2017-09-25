classdef BUtils
    %BUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        function [obs_pos] = get_obs_position(parent_subsystem)
            blocks = find_system(parent_subsystem, 'SearchDepth', '1', 'FindAll', 'on', 'Type', 'Block');
            positions = get_param(blocks, 'Position');
            max_x = 0;
            min_x = 0;
            max_y = 0;
            min_y = 0;
            for idx_pos=1:numel(positions)
                max_x = max(max_x, positions{idx_pos}(1));
                if idx_pos == 1
                    min_x = positions{idx_pos}(1);
                    min_y = positions{idx_pos}(2);
                else
                    min_x = min(min_x, positions{idx_pos}(1));
                    min_y = min(min_y, positions{idx_pos}(2));
                end
            end
            obs_pos = [max_x max_y (max_x + 150) (max_y + 60)];
        end
        
        %%
        function new_name = adapt_block_name(var_name, ID)
            %     new_name = regexprep(var_name,'^__(\w)','$1');
            var_name = char(var_name);
            prefix = '';
            if nargin >= 2
                ID = char(ID);
                %                 display(ID)
                prefix = strcat(ID, '_');
            end
            if numel(prefix)>30
                prefix = strcat('a_', prefix(numel(prefix) - 20 : end));
            end
            if numel(var_name) > 40
                new_name = strcat(prefix,'a_', var_name(numel(var_name) - 30 : end));
            else
                new_name = strcat(prefix, var_name);
            end
            if numel(char(new_name)) > 43
                new_name = BUtils.adapt_block_name(new_name);
            end
            new_name = char(new_name);
        end
        
        
        
        %%
        function block_path  = get_unique_name(block_path)
            n= 1;
            while getSimulinkBlockHandle(block_path) ~= -1
                block_path = strcat(block_path, num2str(n));
            end
        end
        
        %% Get the block name from path
        function out = naming_alone(nomsim)
            [a,~]=regexp (nomsim, filesep, 'split');
            out = a{end};
        end
        %%
        function data = read_EMF(contract_path)
            % read json file
            try
                filetext = fileread(contract_path);
            catch ME
                display_msg('No Contract file', Constants.ERROR, 'Zustre ', '');
                rethrow(ME);
            end
            
            % encode json file
            filetext = regexprep(filetext,'"__','"xx');
            
            %parse the data
            if strcmp(filetext, '')
                warndlg('No cocospec contracts were generated','CoCoSim: Warning');
                return;
            end
            data = jsondecode(filetext);
        end
        
        %%
        function  force_inports_DT(block_name)
            inport_list = find_system(block_name,'BlockType','Inport');
            model = regexp(block_name,'/','split');
            model = model{1};
            if ~isempty(inport_list)
                warning off;
                code_on=sprintf('%s([], [], [], ''compile'')', model);
                eval(code_on);
                port_map = containers.Map();
                for i=1:length(inport_list)
                    port_dt = get_param(inport_list{i}, 'CompiledPortDataTypes');
                    port_map(inport_list{i}) = port_dt.Outport;
                end
                code_off = sprintf('%s([], [], [], ''term'')', model);
                eval(code_off);
                warning on;
                for i=1:length(inport_list)
                    dt = port_map(inport_list{i});
                    set_param(inport_list{i}, 'OutDataTypeStr', dt{1})
                end
            end
        end
        
        %%
        function t = adapt_lustre_text(t)
            t = regexprep(t, '''', '''''');
            t = regexprep(t, '%', '%%');
            t = regexprep(t, '\\', '\\\');
        end
        
        %%
        function verif_node = construct_verif_node(node_struct, node_name, new_node_name)
            %inputs
            node_inputs = node_struct.inputs;
            nb_in = numel(node_inputs);
            inputs_with_type = cell(nb_in,1);
            inputs = cell(nb_in,1);
            for i=1:nb_in
                dt = LusValidateUtils.get_lustre_dt(node_inputs(i).datatype);
                inputs_with_type{i} = sprintf('%s: %s',node_inputs(i).name, dt);
                inputs{i} = node_inputs(i).name;
            end
            inputs_with_type = strjoin(inputs_with_type, ';');
            inputs = strjoin(inputs, ',');
            
            %outputs
            node_outputs = node_struct.outputs;
            nb_out = numel(node_outputs);
            vars_type = cell(nb_out,1);
            outputs_1 = cell(nb_out,1);
            outputs_2 = cell(nb_out,1);
            
            for i=1:nb_out
                dt = LusValidateUtils.get_lustre_dt(node_outputs(i).datatype);
                vars_type{i} = sprintf('%s_1, %s_2: %s;',node_outputs(i).name, ...
                    node_outputs(i).name, dt);
                outputs_1{i} = strcat(node_outputs(i).name, '_1');
                outputs_2{i} = strcat(node_outputs(i).name, '_2');
                ok_exp{i} = sprintf('%s = %s',outputs_1{i}, outputs_2{i});
            end
            vars_type = strjoin(vars_type, '\n');
            outputs_1 = ['(' strjoin(outputs_1, ',') ')'];
            outputs_2 = ['(' strjoin(outputs_2, ',') ')'];
            ok_exp = strjoin(ok_exp, ' and ');
            
            outputs = 'OK:bool';
            header_format = 'node top_verif(%s)\nreturns(%s);\nvar %s\nlet\n';
            header = sprintf(header_format,inputs_with_type, outputs, vars_type);
            
            functions_call_fmt =  '%s = %s(%s);\n%s = %s(%s);\n';
            functions_call = sprintf(functions_call_fmt, outputs_1, node_name, inputs, outputs_2, new_node_name, inputs);
            
            Ok_def = sprintf('OK = %s;\n', ok_exp);
            
            Prop = '--%%PROPERTY  OK=true;';
            
            verif_node = sprintf('%s\n%s\n%s\n%s\ntel', header, functions_call, Ok_def, Prop);
            
        end
    end
    
end

