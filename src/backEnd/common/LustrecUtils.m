classdef LustrecUtils
    %LUSTRECUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        %%
        function t = adapt_lustre_text(t)
            t = regexprep(t, '''', '''''');
            t = regexprep(t, '%', '%%');
            t = regexprep(t, '\\', '\\\');
        end
        
        %%
        function [lusi_path, status] = generate_lusi(lus_file_path, LUSTREC )
            % generate Lusi file
            [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
            lusi_path = fullfile(lus_dir,strcat(lus_fname, '.lusi'));
            if BUtils.isLastModified(lus_file_path, lusi_path)
                msg = sprintf('Lusi file "%s" already generated. It will be used.\n',lusi_path);
                display_msg(msg, MsgType.DEBUG, 'generate_lusi', '');
                status = 0;
                return;
            end
            msg = sprintf('generating lusi for "%s"\n',lus_file_path);
            display_msg(msg, MsgType.INFO, 'generate_lusi', '');
            command = sprintf('%s  -lusi  "%s"',...
                LUSTREC, lus_file_path);
            msg = sprintf('LUSI_LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'generate_lusi', '');
            [status, lusi_out] = system(command);
            if status
                err = sprintf('generation of lusi file failed for file "%s" ',lus_fname);
                display_msg(err, MsgType.ERROR, 'generate_lusi', '');
                display_msg(err, MsgType.DEBUG, 'generate_lusi', '');
                display_msg(lusi_out, MsgType.DEBUG, 'generate_lusi', '');
                cd(OldPwd);
                return
            end
            
        end
        
        %%
        function [emf_path, status] = generate_emf(lus_file_path, LUSTREC, LUCTREC_INCLUDE_DIR)
            [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
            output_dir = fullfile(lus_dir, 'tmp', strcat('tmp_',lus_fname));
            if ~exist(output_dir, 'dir'); mkdir(output_dir); end
            emf_path = fullfile(output_dir,strcat(lus_fname, '.emf'));
            if BUtils.isLastModified(lus_file_path, emf_path)
                status = 0;
                msg = sprintf('emf file "%s" already generated. It will be used.\n',emf_path);
                display_msg(msg, MsgType.DEBUG, 'generate_emf', '');
                return;
            end
            msg = sprintf('generating emf "%s"\n',lus_file_path);
            display_msg(msg, MsgType.INFO, 'generate_emf', '');
            command = sprintf('%s -I "%s" -d "%s" -emf  "%s"',...
                LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, lus_file_path);
            msg = sprintf('EMF_LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'generate_emf', '');
            [status, emf_out] = system(command);
            if status
                err = sprintf('generation of emf failed for file "%s" ',lus_fname);
                display_msg(err, MsgType.WARNING, 'generate_emf', '');
                display_msg(err, MsgType.DEBUG, 'generate_emf', '');
                display_msg(emf_out, MsgType.DEBUG, 'generate_emf', '');
                
                return
            end
            
        end
        
        %% compile_lustre_to_Cbinary
        function err = compile_lustre_to_Cbinary(lus_file_path, node_name, output_dir, LUSTREC,LUCTREC_INCLUDE_DIR)
            [~, file_name, ~] = fileparts(lus_file_path);
            makefile_name = fullfile(output_dir,strcat(file_name,'.makefile'));
            binary_name = fullfile(output_dir,strcat(file_name,'_', node_name));
            % generate C code
            if BUtils.isLastModified(lus_file_path, binary_name)
                err = 0;
                display_msg(['file ' binary_name ' has been already generated.'], MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                return;
            end
            command = sprintf('%s -I "%s" -d "%s" -node %s "%s"',LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, node_name, lus_file_path);
            msg = sprintf('LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            [status, lustre_out] = system(command);
            err = 0;
            if status
                display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                msg = sprintf('lustrec failed for model "%s"',lus_file_path);
                display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
                display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                display_msg(lustre_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                err = 1;
                return
            end
            OldPwd = pwd;
            
            % generate C binary
            cd(output_dir);
            msg = sprintf('start compiling model "%s"\n',file_name);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            command = sprintf('make -f "%s"', makefile_name);
            msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            [status, make_out] = system(command);
            if status
                msg = sprintf('Compilation failed for model "%s" ',file_name);
                display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
                display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                display_msg(make_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                err = 1;
                cd(OldPwd);
                return
            end
            
        end
        %% node inputs outputs
        function [node_struct, status] = extract_node_struct(lus_file_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR)
            [node_struct, status] = LustrecUtils.extract_node_struct_using_emf(lus_file_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);
            if status==0
                return;
            end
            [lusi_path, status] = LustrecUtils.generate_lusi(lus_file_path, LUSTREC );
            if status
                display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                    node_name, lus_file_path), MsgType.Error, 'extract_node_struct', '');
                return;
            end
            lusi_text = fileread(lusi_path);
            vars = '(\s*\w+\s*:\s*(int|real|bool);?)+';
            pattern = strcat('(node|function)\s+',node_name,'\s*\(', vars, '\)\s*returns\s*\(', vars,'\);');
            tokens = regexp(lusi_text, pattern,'match');
            if isempty(tokens)
                status = 1;
                display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                    node_name, lus_file_path), MsgType.ERROR, 'extract_node_struct', '');
                return;
            end
            tokens = regexp(tokens{1}, vars,'match');
            inputs = regexp(tokens{1}, ';', 'split');
            outputs = regexp(tokens{2}, ';', 'split');
            
            for i=1:numel(inputs)
                tokens = regexp(inputs{i}, '\w+','match');
                node_struct.inputs(i).name = tokens{1};
                node_struct.inputs(i).datatype = tokens{2};
            end
            for i=1:numel(outputs)
                tokens = regexp(outputs{i}, '\w+','match');
                node_struct.outputs(i).name = tokens{1};
                node_struct.outputs(i).datatype = tokens{2};
            end
        end
        
        function [main_node_struct, status] = extract_node_struct_using_emf(lus_file_path, main_node_name, LUSTREC, LUCTREC_INCLUDE_DIR)
            main_node_struct = [];
            [contract_path, status] = LustrecUtils.generate_emf(lus_file_path, LUSTREC, LUCTREC_INCLUDE_DIR);
            
            if status==0
                % extract main node struct from EMF
                data = BUtils.read_EMF(contract_path);
                nodes = data.nodes;
                nodes_names = fieldnames(nodes)';
                idx_main_node = find(ismember(nodes_names, main_node_name));
                if isempty(idx_main_node)
                    display_msg(['Node ' main_node_name ' does not exist in EMF ' contract_path], MsgType.ERROR, 'Validation', '');
                    status = 1;
                    return;
                end
                main_node_struct = nodes.(nodes_names{idx_main_node});
                
            end
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
        
        %% verification file
        function verif_lus_path = create_mutant_verif_file(lus_file_path, mutant_lus_file_path, node_struct, node_name, new_node_name)
            % create verification file
            [file_parent, mutant_lus_file_name, ~] = fileparts(mutant_lus_file_path);
            output_dir = fullfile(file_parent, strcat(mutant_lus_file_name, '_build'));
            if ~exist(output_dir, 'dir'); mkdir(output_dir); end
            verif_lus_path = fullfile(output_dir, strcat(mutant_lus_file_name, '_verif.lus'));
            
            if BUtils.isLastModified(mutant_lus_file_path, verif_lus_path)
                display_msg(['file ' verif_lus_path ' has been already generated'], MsgType.DEBUG, 'Validation', '');
                return;
            end
            filetext1 = LustrecUtils.adapt_lustre_text(fileread(lus_file_path));
            sep_line = '--******************** second file ********************';
            filetext2 = LustrecUtils.adapt_lustre_text(fileread(mutant_lus_file_path));
            filetext2 = regexprep(filetext2, '#open\s*<\w+>','');
            verif_line = '--******************** sVerification node ********************';
            verif_node = LustrecUtils.construct_verif_node(node_struct, node_name, new_node_name);
            
            verif_lus_text = sprintf('%s\n%s\n%s\n%s\n%s', filetext1, sep_line, filetext2, verif_line, verif_node);
            
            
            fid = fopen(verif_lus_path, 'w');
            fprintf(fid, verif_lus_text);
            fclose(fid);
        end
        
        %% run Zustre or kind2 on verification file
        function [answer, CEX] = run_verif(verif_lus_path, Verif_dir, node_name, Backend)
            answer = '';
            CEX = [];
            if nargin < 1
                status = 1;
                error('Missing arguments to function call: LustrecUtils.run_verif')
            end
            [file_dir, file_name, ~] = fileparts(verif_lus_path);
            if nargin < 2 || isempty(Verif_dir)
                Verif_dir = file_dir;
            end
            if nargin < 3 || isempty(node_name)
                node_name = 'top';
            end
            if nargin < 4 || isempty(Backend)
                Backend = 'KIND2';
            end
            timeout = '600';
            cd(Verif_dir);
            tools_config;
            if strcmp(Backend, 'ZUSTRE') || strcmp(Backend, 'Z')
                command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
                    ZUSTRE, verif_lus_path, node_name, timeout);
                display_msg(['ZUSTRE_COMMAND ' command], MsgType.DEBUG, 'LustrecUtils.run_verif', '');
                
            elseif strcmp(Backend, 'KIND2') || strcmp(Backend, 'K')
                command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
                    KIND2, Z3, timeout, node_name, verif_lus_path);
                display_msg(['KIND2_COMMAND ' command], MsgType.DEBUG, 'LustrecUtils.run_verif', '');
                
            end
            [~, solver_output] = system(command);
            display_msg(solver_output, MsgType.DEBUG, 'LustrecUtils.run_verif', '');
            [answer, CEX] = LustrecUtils.extract_answer(solver_output,Backend,  file_name, node_name,  Verif_dir);
            
        end
        
        function [answer, CEX] = extract_answer(solver_output,solver,  file_name, node_name,  output_dir)
            answer = '';
            CEX = [];
            if isempty(solver_output)
                return
            end
            tmp_file = fullfile(output_dir, strcat(file_name, '_', node_name));
            fid = fopen(tmp_file, 'w');
            if fid == -1
                display_msg(['Couldn''t create file ' tmp_file],...
                    MsgType.ERROR, 'LustrecUtils.extract_answer', '');
                return;
            end
            fprintf(fid, solver_output);
            fclose(fid);
            xDoc = xmlread(tmp_file);
            xProperties = xDoc.getElementsByTagName('Property');
            property = xProperties.item(0);
            answer = property.getElementsByTagName('Answer').item(0).getTextContent;
            
            if strcmp(solver, 'KIND2') || strcmp(solver, 'JKIND') ...
                || strcmp(solver, 'K') || strcmp(solver, 'J')
                if strcmp(answer, 'valid')
                    answer = 'SAFE';
                elseif strcmp(answer, 'falsifiable')
                    answer = 'CEX';
                else
                    answer = 'UNKNOWN';
                end
            end
            if strcmp(answer, 'CEX') 
                if strcmp(solver, 'JKIND') || strcmp(solver, 'J')
                    xml_cex = xDoc.getElementsByTagName('Counterexample');
                else
                    xml_cex = xDoc.getElementsByTagName('CounterExample');
                end
                if xml_cex.getLength > 0
                    CEX = xml_cex;
                else
                    msg = sprintf('Could not parse counter example from %s', solver_output);
                    display_msg(msg, Constants.ERROR, 'Property Checking', '');
                end
            end
            msg = sprintf('Solver Result of property in node %s is %s', node_name, answer);
            display_msg(msg, Constants.RESULT, 'LustrecUtils.extract_answer', '');
        end
    end
    
end


