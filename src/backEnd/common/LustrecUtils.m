classdef LustrecUtils < handle
    %LUSTRECUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        %%
        function t = adapt_lustre_text(t, dest)
            if nargin < 2
                dest = '';
            end
            t = regexprep(t, '''', '''''');
            t = regexprep(t, '%', '%%');
            t = regexprep(t, '\\', '\\\');
            t = regexprep(t, '!=', '<>');
            if strcmp(dest, 'Kind2')
                t = regexprep(t, '\(\*! /coverage/mcdc/:', '(* /coverage/mcdc/:');
            end
        end
        
        function new_mcdc_file = adapt_lustre_file(mcdc_file, dest)
            % adapt lustre code
            if nargin < 2
                dest = '';
            end
            if ~exist(mcdc_file, 'file')
                display_msg(['File not found ' mcdc_file], MsgType.ERROR, 'adapt_lustre_file', '');
                return;
            end
            [output_dir, lus_file_name, ~] = fileparts(mcdc_file);
            new_mcdc_file = fullfile(output_dir,strcat( lus_file_name, '_adapted.lus'));
            fid = fopen(new_mcdc_file, 'w');
            if fid > 0
                fprintf(fid, '%s', LustrecUtils.adapt_lustre_text(fileread(mcdc_file), dest));
                fclose(fid);
            else
                new_mcdc_file = mcdc_file;
            end 
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
        function [emf_path, status] = ...
                generate_emf(lus_file_path, output_dir, ...
                LUSTREC,...
                LUCTREC_INCLUDE_DIR)
            if nargin < 4
                tools_config;
                status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
                if status
                    err = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
                    display_msg(err, MsgType.ERROR, 'generate_lusi', '');
                    return;
                end
            end
            [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
            if nargin < 2 || isempty(output_dir)
                output_dir = fullfile(lus_dir, 'cocosim_tmp', lus_fname);
            end
            
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
            command = sprintf('%s -I "%s" -d "%s" -algebraic-loop-solve -emf  "%s"',...
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
        
        %%
        function [mcdc_file] = generate_MCDCLustreFile(lus_full_path, output_dir)
            [~, lus_file_name, ~] = fileparts(lus_full_path);
            tools_config;
            status = BUtils.check_files_exist(LUSTRET);
            if status
                msg = 'LUSTRET not found, please configure tools_config file under tools folder';
                display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
                return;
            end
            command = sprintf('%s -I %s -d %s -mcdc-cond  %s',LUSTRET, LUCTREC_INCLUDE_DIR, output_dir, lus_full_path);
            msg = sprintf('LUSTRET_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
            [status, lustret_out] = system(command);
            if status
                msg = sprintf('lustret failed for model "%s"',lus_file_name);
                display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
                display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
                display_msg(msg, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
                display_msg(lustret_out, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
                return
            end
            
            mcdc_file = fullfile(output_dir,strcat( lus_file_name, '.mcdc.lus'));
            if ~exist(mcdc_file, 'file')
                display_msg(['No mcdc file has been found in ' output_dir ' with name ' ...
                    strcat( lus_file_name, '.mcdc.lus')], MsgType.ERROR, 'generate_MCDCLustreFile', '');
                return;
            end
            
        end
        %% compile_lustre_to_Cbinary
        function err = compile_lustre_to_Cbinary(lus_file_path, ...
                node_name, ...
                output_dir, ...
                LUSTREC,...
                LUCTREC_INCLUDE_DIR)
            if nargin < 4
                tools_config;
                err = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
                if err
                    msg = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
                    display_msg(msg, MsgType.ERROR, 'generate_lusi', '');
                    return;
                end
            end
            [~, file_name, ~] = fileparts(lus_file_path);
           
            binary_name = fullfile(output_dir,...
                strcat(file_name,'_', node_name));
            % generate C code
            if BUtils.isLastModified(lus_file_path, binary_name)
                err = 0;
                display_msg(['file ' binary_name ' has been already generated.'],...
                    MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
                return;
            end
            %-algebraic-loop-solve should be added
            command = sprintf('%s -algebraic-loop-solve -I "%s" -d "%s" -node %s "%s"',...
                LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, node_name, lus_file_path);
            msg = sprintf('LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            [err, lustre_out] = system(command);
            if err
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
            makefile_name = fullfile(output_dir,strcat(file_name,'.makefile'));
            msg = sprintf('start compiling model "%s"\n',file_name);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            command = sprintf('make -f "%s"', makefile_name);
            msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
            display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
            [err, make_out] = system(command);
            if err
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
        function [node_struct,...
                status] = extract_node_struct(lus_file_path,...
                node_name,...
                LUSTREC,...
                LUCTREC_INCLUDE_DIR)
            if nargin < 3
                tools_config;
                status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
                if status
                    err = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
                    display_msg(err, MsgType.ERROR, 'generate_lusi', '');
                    return;
                end
            end
            try
                [node_struct, status] = ...
                    LustrecUtils.extract_node_struct_using_emf(...
                    lus_file_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);
            catch
                status = 1;
            end
            if status==0
                return;
            end
            
            try
                [node_struct, status] = ...
                    LustrecUtils.extract_node_struct_using_lusi(...
                    lus_file_path, node_name, LUSTREC);
            catch
                status = 1;
            end
        end
        
        function [node_struct,...
                status] = extract_node_struct_using_lusi(lus_file_path,...
                node_name,...
                LUSTREC)
            [lusi_path, status] = ...
                LustrecUtils.generate_lusi(lus_file_path, LUSTREC );
            if status
                display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                    node_name, lus_file_path), MsgType.Error, 'extract_node_struct', '');
                return;
            end
            lusi_text = fileread(lusi_path);
            vars = '(\s*\w+\s*:\s*(int|real|bool);?)+';
            pattern = strcat(...
                '(node|function)\s+',...
                node_name,...
                '\s*\(',...
                vars,...
                '\)\s*returns\s*\(',...
                vars,'\);');
            tokens = regexp(lusi_text, pattern,'match');
            if isempty(tokens)
                status = 1;
                display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                    node_name, lus_file_path),...
                    MsgType.ERROR, 'extract_node_struct', '');
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
        
        function [main_node_struct, ...
                status] = extract_node_struct_using_emf(...
                lus_file_path,...
                main_node_name,...
                LUSTREC, ...
                LUCTREC_INCLUDE_DIR)
            main_node_struct = [];
            [contract_path, status] = LustrecUtils.generate_emf(...
                lus_file_path, '', LUSTREC, LUCTREC_INCLUDE_DIR);
            
            if status==0
                % extract main node struct from EMF
                data = BUtils.read_json(contract_path);
                nodes = data.nodes;
                nodes_names = fieldnames(nodes)';
                orig_names = arrayfun(@(x)  nodes.(x{1}).original_name,...
                    nodes_names, 'UniformOutput', false);
                idx_main_node = find(ismember(orig_names, main_node_name));
                if isempty(idx_main_node)
                    display_msg(...
                        ['Node ' main_node_name ' does not exist in EMF ' contract_path], ...
                        MsgType.ERROR, 'Validation', '');
                    status = 1;
                    return;
                end
                main_node_struct = nodes.(nodes_names{idx_main_node});
                
            end
        end
        
        %%
        function verif_node = construct_verif_node(...
                node_struct, node_name, new_node_name)
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
            functions_call = sprintf(functions_call_fmt,...
                outputs_1, node_name, inputs, outputs_2, new_node_name, inputs);
            
            Ok_def = sprintf('OK = %s;\n', ok_exp);
            
            Prop = '--%%PROPERTY  OK=true;';
            
            verif_node = sprintf('%s\n%s\n%s\n%s\ntel',...
                header, functions_call, Ok_def, Prop);
            
        end
        %% construct_EMF_verif_model
        function status = check_DType_and_Dimensions(slx_file_name)
            status = 0;
            sys_list = find_system(slx_file_name, 'LookUnderMasks', 'all',...
                'RegExp', 'on', 'OutDataTypeStr', '[u]?int(8|16)');
            if ~isempty(sys_list)
                msg = sprintf('Model contains integers ports differens than int32.');
                msg = [msg, 'Lus2slx current version support only int32 dataType'];
                display_msg(msg, MsgType.ERROR, ...
                    'LustrecUtils.check_DType_and_Dimensions','');
                status = 1;
                return;
            end
            % Dimensions should be less than 2
            inport_list = find_system(slx_file_name, 'SearchDepth', 1, 'BlockType', 'Inport');
            try
                code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
                eval(code_on);
            catch
            end
            dimensions = get_param(inport_list, 'CompiledPortDimensions');
            outport_dimensions = cellfun(@(x) x.Outport, dimensions, 'un', 0);
            for i=1:numel(outport_dimensions)
                dim = outport_dimensions{i};
                if numel(dim) > 3
                    
                    
                    msg = sprintf('Invalid inport dimension "%s" with dimension %s: Lus2slx functions does not support dimension > 2.',...
                        inport_list{i}, num2str(dim));
                    display_msg(msg, MsgType.ERROR, ...
                        'LustrecUtils.check_DType_and_Dimensions','');
                    status = 1;
                    break;
                    
                    
                end
            end
            code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
            eval(code_off);
        end
        
        function inport_idx = add_demux(new_model_name, inport_idx, inport_name, dim,...
                demux_outHandle, demux_inHandle)
            p = get_param(demux_outHandle.Inport(inport_idx), 'Position');
            x = p(1) - 50*inport_idx;
            y = p(2);
            demux_path = strcat(new_model_name,'/Demux',inport_name);
            demux_pos(1) = (x - 10);
            demux_pos(2) = (y - 10);
            demux_pos(3) = (x + 10);
            demux_pos(4) = (y + 50 * dim);
            h = add_block('simulink/Signal Routing/Demux',...
                demux_path,...
                'MakeNameUnique', 'on', ...
                'Outputs', num2str(dim),...
                'Position',demux_pos);
            demux_Porthandl = get_param(h, 'PortHandles');
            add_line(new_model_name,...
                demux_inHandle.Outport(1),...
                demux_Porthandl.Inport(1), ...
                'autorouting', 'on');
            for j=1:dim
                add_line(new_model_name,...
                    demux_Porthandl.Outport(j),...
                    demux_outHandle.Inport(inport_idx), ...
                    'autorouting', 'on');
                inport_idx = inport_idx + 1;
            end
        end
        
        function idx = add_mux(new_model_name, outport_idx, i, muxID, dim,...
                mux_inHandle, mux_outHandle, dim_3, colon )
            p = get_param(mux_inHandle.Outport(outport_idx+1), 'Position');
            x = p(1) + 50;
            y = p(2);
            mux_path = strcat(new_model_name,'/Mux',muxID);
            mux_pos(1) = (x - 10);
            mux_pos(2) = (y - 10);
            mux_pos(3) = (x + 10);
            mux_pos(4) = (y + 50 * dim);
            h = add_block('simulink/Signal Routing/Mux',...
                mux_path,...
                'MakeNameUnique', 'on', ...
                'Inputs', num2str(dim),...
                'Position',mux_pos);
            mux_Porthandl = get_param(h, 'PortHandles');
            add_line(new_model_name,...
                mux_Porthandl.Outport(1),...
                mux_outHandle.Inport(i), ...
                'autorouting', 'on');
            for j=1:dim
                idx = outport_idx + dim_3*(j-1) + colon;
                add_line(new_model_name,...
                    mux_inHandle.Outport(idx), ...
                    mux_Porthandl.Inport(j),...
                    'autorouting', 'on');
                
            end
        end
        function [status, new_name_path] = construct_EMF_verif_model(slx_file_name,...
                lus_file_path, node_name, output_dir)
            new_name_path = '';
            [status] = LustrecUtils.check_DType_and_Dimensions(slx_file_name);
            if status
                return;
            end
            tools_config;
            status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
            if status
                return;
            end
            %1- Generate Simulink model from original Lustre file using EMF
            %backend.
            
            %generate emf json
            [emf_path, status] = ...
                LustrecUtils.generate_emf(lus_file_path, output_dir, ...
                LUSTREC, LUCTREC_INCLUDE_DIR);
            if status
                return;
            end
            
            %generate simulink model
            new_model_name = BUtils.adapt_block_name(strcat(slx_file_name,'_Verif'));
            clear lus2slx
            [status, new_name_path, ~] = lus2slx(emf_path, output_dir, new_model_name, node_name, 0);
            if status
                return;
            end
            
            %2- Create Simulink model containing both SLX1 and SLX2
            load_system(new_name_path);
            
            emf_sub_path = fullfile(new_model_name, BUtils.adapt_block_name(node_name));
            emf_pos = get_param(emf_sub_path, 'Position');
            % copy contents of slx_file to a subsytem
            
            original_sub_path = fullfile(new_model_name, 'original');
            add_block('built-in/Subsystem', original_sub_path);
            load_system(slx_file_name);
            Simulink.BlockDiagram.copyContentsToSubsystem(slx_file_name, original_sub_path);
            
            %add inputs and outputs for original subsystem
            OrigSubPortHandles = get_param(original_sub_path, 'PortHandles');
            nb_inports = numel(OrigSubPortHandles.Inport);
            nb_outports = numel(OrigSubPortHandles.Outport);
            m = max(nb_inports, nb_outports);
            set_param(original_sub_path,'Position',[emf_pos(1), emf_pos(2), emf_pos(3), emf_pos(2) + 50 * m]);
            emf_pos(2) = emf_pos(2) + 50 * m + 50;
            set_param(emf_sub_path,'Position',[emf_pos(1), emf_pos(2), emf_pos(3), emf_pos(2) + 50 * m]);
            
            portHandlesEMF = get_param(emf_sub_path, 'PortHandles');
            emf_inport_idx = 1;
            for i=1:nb_inports
                p = get_param(OrigSubPortHandles.Inport(i), 'Position');
                x = p(1) - 50;
                y = p(2);
                inport_name = strcat(new_model_name,'/In',num2str(i));
                inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                    inport_name,...
                    'MakeNameUnique', 'on', ...
                    'Position',[(x-10) (y-10) (x+10) (y+10)]);
                inportPortHandle = get_param(inport_handle,'PortHandles');
                add_line(new_model_name,...
                    inportPortHandle.Outport(1), OrigSubPortHandles.Inport(i),...
                    'autorouting', 'on');
                
                %add the inport to emf subsytem, it depends to dimension we should
                %inline vectors
                code_on=sprintf('%s([], [], [], ''compile'')', new_model_name);
                eval(code_on);
                dim_struct = get_param(inport_handle, 'CompiledPortDimensions');
                code_off=sprintf('%s([], [], [], ''term'')', new_model_name);
                eval(code_off);
                isMatrix = false;
                if numel(dim_struct.Outport)==1
                     dim = dim_struct.Outport;
                elseif numel(dim_struct.Outport)==2 
                    if (dim_struct.Outport(1)==1 || dim_struct.Outport(2)==1)
                        dim = dim_struct.Outport(1) * dim_struct.Outport(2);
                    else
                        isMatrix = true;
                        dim = dim_struct.Outport;
                    end
                elseif numel(dim_struct.Outport) == 3
                    if  (dim_struct.Outport(2)==1 || dim_struct.Outport(3)==1)
                        dim = dim_struct.Outport(2) * dim_struct.Outport(3);
                    else
                        isMatrix = true;
                        dim = dim_struct.Outport;
                    end
                else
                    msg = sprintf('Invalid inport "%s": We do not support dimension [%s].',...
                        get_param(inport_handle, 'Name'), num2str(dim_struct.Outport));
                    display_msg(msg, MsgType.ERROR, ...
                        'compare_slx_lus','');
                    status = 1;
                    return;
                end
                if dim == 1
                    add_line(new_model_name,...
                        inportPortHandle.Outport(1), portHandlesEMF.Inport(emf_inport_idx), ...
                        'autorouting', 'on');
                    emf_inport_idx = emf_inport_idx + 1;
                elseif ~isMatrix
                    emf_inport_idx = ...
                        LustrecUtils.add_demux(new_model_name, emf_inport_idx, ...
                        strcat('In',num2str(i)), dim, portHandlesEMF, inportPortHandle);
                elseif isMatrix
                    for colon=1:dim(2)
                        selector_path = strcat(new_model_name,'/Selector_',...
                            strcat('In',num2str(i)), num2str(colon));
                        IndexParamArray{1} = num2str(colon);
                        IndexParamArray{2} = '1';
                        h = add_block('simulink/Signal Routing/Selector',...
                            selector_path,...
                            'MakeNameUnique', 'on', ...
                            'IndexMode', 'One-based',...
                            'IndexParamArray', IndexParamArray, ...
                            'NumberOfDimensions', '2',...
                            'IndexOptions','Index vector (dialog),Select all');
                        concat_Porthandl = get_param(h, 'PortHandles');
                        add_line(new_model_name,...
                            inportPortHandle.Outport(1),...
                            concat_Porthandl.Inport(1), ...
                            'autorouting', 'on');
                        demuxID = strcat('In',num2str(i),'_', num2str(colon));
                        emf_inport_idx = ...
                            LustrecUtils.add_demux(new_model_name, emf_inport_idx, ...
                            demuxID, dim(3), portHandlesEMF, concat_Porthandl);
                    end
                    
                end
            end
            % add verification subsystem
            emf_pos = get_param(emf_sub_path, 'Position');
            orig_pos = get_param(original_sub_path, 'Position');
            verif_pos(1) = emf_pos(3) + 100;
            verif_pos(2) = (emf_pos(2) + orig_pos(2)) / 2;
            verif_pos(3) = emf_pos(3) + 300;
            verif_pos(4) = (emf_pos(4) + orig_pos(4)) / 2;
            verif_sub_path = fullfile(new_model_name, 'verif');
            add_block('built-in/Subsystem', verif_sub_path, ...
                'Position',verif_pos, ...
                'TreatAsAtomicUnit', 'on');
            
            mask = Simulink.Mask.create(verif_sub_path);
            mask.Type = 'VerificationSubsystem';
            set_param(verif_sub_path, 'ForegroundColor', 'red');
            set_param(verif_sub_path, 'BackgroundColor', 'white');
            
            x = (50 * nb_outports +120) / 2;
            Assertion_path = strcat(verif_sub_path,'/assert');
            add_block('simulink/Model Verification/Assertion',...
                Assertion_path,...
                'MakeNameUnique', 'on',...
                'Position', [450, x - 20,  550,  x + 20]...
                );
            
            if nb_outports >= 2
                AND_path = strcat(verif_sub_path,'/AND');
                add_block('simulink/Logic and Bit Operations/Logical Operator',...
                    AND_path,...
                    'MakeNameUnique', 'on',...
                    'NumInputPorts', num2str(nb_outports), ...
                    'Position', [350, 75,  370,  50 * (nb_outports + 1)]...
                    );
                add_line(verif_sub_path, ...
                    strcat('AND', '/1'),...
                    strcat('assert', '/1'),...
                    'autorouting', 'on');
            end
            
            j = 1;
            for i=1:2:2*nb_outports
                inport_name1 = strcat(verif_sub_path,'/In',num2str(i));
                add_block('simulink/Ports & Subsystems/In1',...
                    inport_name1,...
                    'MakeNameUnique', 'on',...
                    'Position', [50, 50*i,  70,  50*i + 20]...
                    );
                inport_name2 = strcat(verif_sub_path,'/In',num2str(i+1));
                add_block('simulink/Ports & Subsystems/In1',...
                    inport_name2,...
                    'MakeNameUnique', 'on',...
                    'Position', [50, 50*(i+1),  70,  50*(i+1) + 20]...
                    );
                equal_path = strcat(verif_sub_path,'/Equal',num2str(j));
                add_block('simulink/Logic and Bit Operations/Relational Operator',...
                    equal_path,...
                    'MakeNameUnique', 'on',...
                    'OutDataTypeStr', 'fixdt(1,16)', ...
                    'Operator', '==', ...
                    'Position', [150, 50*i+25,  170,  50*i + 45]...
                    );
                
                add_line(verif_sub_path, ...
                    strcat('In',num2str(i), '/1'), ...
                    strcat('Equal',num2str(j), '/1'), ...
                    'autorouting', 'on');
                add_line(verif_sub_path, ...
                    strcat('In',num2str(i+1), '/1'),...
                    strcat('Equal',num2str(j), '/2'),...
                    'autorouting', 'on');
                
                % Add product of elements for vectors inports
                product_path = strcat(verif_sub_path,'/Product',num2str(j));
                add_block('simulink/Math Operations/Product of Elements',...
                    product_path,...
                    'MakeNameUnique', 'on',...
                    'Position', [250, 50*i+25,  270,  50*i + 45]...
                    );
                
                add_line(verif_sub_path, ...
                    strcat('Equal',num2str(j), '/1'),...
                    strcat('Product',num2str(j), '/1'),...
                    'autorouting', 'on');
                
                if nb_outports >= 2
                    add_line(verif_sub_path, ...
                        strcat('Product',num2str(j), '/1'),...
                        strcat('AND', '/',num2str(j)),...
                        'autorouting', 'on');
                    
                else
                    add_line(verif_sub_path, ...
                        strcat('Product',num2str(j), '/1'),...
                        strcat('assert', '/1'),...
                        'autorouting', 'on');
                end
                j = j + 1;
            end
            
            %link outports
            VerifportHandles = get_param(verif_sub_path, 'PortHandles');
            outport_idx = 0;
            
            for i=1:nb_outports
                add_line(new_model_name, OrigSubPortHandles.Outport(i), VerifportHandles.Inport(2*i-1), 'autorouting', 'on');
                code_on=sprintf('%s([], [], [], ''compile'')', new_model_name);
                eval(code_on);
                dim_struct = get_param(OrigSubPortHandles.Outport(i), 'CompiledPortDimensions');
                code_off=sprintf('%s([], [], [], ''term'')', new_model_name);
                eval(code_off);
                isMatrix = false;
                if numel(dim_struct)==1
                     dim = dim_struct;
                elseif numel(dim_struct)==2 
                    if (dim_struct(1)==1 || dim_struct(2)==1)
                        dim = dim_struct(1) * dim_struct(2);
                    else
                        isMatrix = true;
                        dim = dim_struct;
                    end
                elseif numel(dim_struct) == 3
                    if  (dim_struct(2)==1 || dim_struct(3)==1)
                        dim = dim_struct(2) * dim_struct(3);
                    else
                        isMatrix = true;
                        dim = dim_struct;
                    end
                else
                    msg = sprintf('Invalid inport "%s": We do not support dimension [%s].',...
                        get_param(OrigSubPortHandles.Outport(i), 'Name'), num2str(dim_struct));
                    display_msg(msg, MsgType.ERROR, ...
                        'compare_slx_lus','');
                    status = 1;
                    return;
                end
                
                
                if dim == 1
                    outport_idx = outport_idx + 1;
                    add_line(new_model_name, portHandlesEMF.Outport(outport_idx), VerifportHandles.Inport(2*i), 'autorouting', 'on');
                elseif ~isMatrix
                    outport_idx = LustrecUtils.add_mux(new_model_name, outport_idx, 2*i, num2str(i), dim,...
                        portHandlesEMF, VerifportHandles, 1, 1 );
                elseif isMatrix
                    concat_path = strcat(new_model_name,'/Concatenate_',...
                            strcat('Out',num2str(i)));
                        NumInputs = dim(3);
                        h = add_block('simulink/Math Operations/Vector Concatenate',...
                            concat_path,...
                            'MakeNameUnique', 'on', ...
                            'NumInputs', num2str(NumInputs), ...
                            'ConcatenateDimension', '2',...
                            'Mode','Multidimensional array');
                        concat_Porthandl = get_param(h, 'PortHandles');
                    for colon=1:dim(3)
                        
                        muxID = strcat('Out',num2str(i),'_', num2str(colon));
                        last_index = LustrecUtils.add_mux(new_model_name, outport_idx, colon, muxID, dim(2),...
                            portHandlesEMF, concat_Porthandl, dim(3), colon );
                    end
                    add_line(new_model_name,...
                                concat_Porthandl.Outport(1),...
                                VerifportHandles.Inport(2*i), ...
                                'autorouting', 'on');
                    outport_idx = last_index;
                end
            end
            
            %add inputs and outputs for EMF subsystem
            
            save_system(new_name_path);
        end
        %% construct EMF  model
        function [status, new_name_path, emf_path, xml_trace] = construct_EMF_model(...
                lus_file_path, node_name, output_dir)
            tools_config;
            status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
            if status
                return;
            end
            %1- Generate Simulink model from original Lustre file using EMF
            %backend.
            
            %generate emf json
            [emf_path, status] = ...
                LustrecUtils.generate_emf(lus_file_path, output_dir, ...
                LUSTREC, LUCTREC_INCLUDE_DIR);
            if status
                return;
            end
            
            [~, lus_fname, ~] = fileparts(lus_file_path);
            %generate simulink model
            if ~strcmp(lus_fname, node_name)
                new_model_name = BUtils.adapt_block_name(strcat(lus_fname,'_',node_name));
            else
                new_model_name = BUtils.adapt_block_name(strcat(lus_fname,'_EMF'));
            end
            clear lus2slx
            [status, new_name_path, xml_trace] = lus2slx(emf_path, output_dir, new_model_name, node_name, 0);
            if status
                return;
            end
            
            %2- Create Simulink model containing both SLX1 and SLX2
            load_system(new_name_path);
            
            main_block_path = strcat(new_model_name,'/', BUtils.adapt_block_name(node_name));
            portHandles = get_param(main_block_path, 'PortHandles');
            nb_inports = numel(portHandles.Inport);
            nb_outports = numel(portHandles.Outport);
            m = max(nb_inports, nb_outports);
            set_param(main_block_path,'Position',[100 0 (100+250) (0+50*m)]);
            
            for i=1:nb_inports
                p = get_param(portHandles.Inport(i), 'Position');
                x = p(1) - 50;
                y = p(2);
                inport_name = strcat(new_model_name,'/In',num2str(i));
                add_block('simulink/Ports & Subsystems/In1',...
                    inport_name,...
                    'Position',[(x-10) (y-10) (x+10) (y+10)]);
                SrcBlkH = get_param(inport_name,'PortHandles');
                add_line(new_model_name, SrcBlkH.Outport(1), portHandles.Inport(i), 'autorouting', 'on');
            end
            
            for i=1:nb_outports
                p = get_param(portHandles.Outport(i), 'Position');
                x = p(1) + 50;
                y = p(2);
                outport_name = strcat(new_model_name,'/Out',num2str(i));
                add_block('simulink/Ports & Subsystems/Out1',...
                    outport_name,...
                    'Position',[(x-10) (y-10) (x+10) (y+10)]);
                DstBlkH = get_param(outport_name,'PortHandles');
                add_line(new_model_name, portHandles.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
            end
            %% Save system
            configSet = getActiveConfigSet(new_model_name);
            set_param(configSet, 'Solver', 'FixedStepDiscrete', 'FixedStep', '1');
            save_system(new_model_name,'','OverwriteIfChangedOnDisk',true);
            
        end
        %% verification file
        function verif_lus_path = create_mutant_verif_file(...
                lus_file_path,...
                mutant_lus_fpath, ...
                node_struct, ...
                node_name, ...
                new_node_name)
            % create verification file
            [file_parent, mutant_lus_file_name, ~] = fileparts(mutant_lus_fpath);
            output_dir = fullfile(...
                file_parent, strcat(mutant_lus_file_name, '_build'));
            if ~exist(output_dir, 'dir'); mkdir(output_dir); end
            verif_lus_path = fullfile(...
                output_dir, strcat(mutant_lus_file_name, '_verif.lus'));
            
            if BUtils.isLastModified(mutant_lus_fpath, verif_lus_path)...
                    && BUtils.isLastModified(lus_file_path, verif_lus_path)
                display_msg(...
                    ['file ' verif_lus_path ' has been already generated'],...
                    MsgType.DEBUG,...
                    'Validation', '');
                return;
            end
            filetext1 = ...
                LustrecUtils.adapt_lustre_text(fileread(lus_file_path));
            sep_line =...
                '--******************** second file ********************';
            filetext2 = ...
                LustrecUtils.adapt_lustre_text(fileread(mutant_lus_fpath));
            filetext2 = regexprep(filetext2, '#open\s*<\w+>','');
            verif_line = ...
                '--******************** sVerification node *************';
            verif_node = LustrecUtils.construct_verif_node(...
                node_struct, node_name, new_node_name);
            
            verif_lus_text = sprintf('%s\n%s\n%s\n%s\n%s', ...
                filetext1, sep_line, filetext2, verif_line, verif_node);
            
            
            fid = fopen(verif_lus_path, 'w');
            fprintf(fid, verif_lus_text);
            fclose(fid);
        end
        %% compositional verification file between EMF and cocosim
        function [verif_lus_path, nodes_list] = create_emf_verif_file(...
                lus_file_path,...
                coco_lus_fpath,...
                emf_path, ...
                EMF_trace_xml, ...
                cocosim_trace_file)
            nodes_list = {};
            % create verification file
            [output_dir, coco_lus_file_name, ~] = fileparts(coco_lus_fpath);
            verif_lus_path = fullfile(...
                output_dir, strcat(coco_lus_file_name, '_verif.lus'));
            
            if BUtils.isLastModified(coco_lus_fpath, verif_lus_path) ...
                    && BUtils.isLastModified(lus_file_path, verif_lus_path)
                display_msg(...
                    ['file ' verif_lus_path ' has been already generated'],...
                    MsgType.DEBUG,...
                    'Validation', '');
                return;
            end
            filetext1 = ...
                LustrecUtils.adapt_lustre_text(fileread(coco_lus_fpath));
            sep_line =...
                '--******************** second file ********************';
            filetext2 = ...
                LustrecUtils.adapt_lustre_text(fileread(lus_file_path));
            filetext2 = regexprep(filetext2, '#open\s*<\w+>','');
            
            [~, emf_model_name, ~] = fileparts(EMF_trace_xml.model_full_path);
            
            try
                DOMNODE = xmlread(cocosim_trace_file);
            catch
                display_msg(...
                    ['file ' cocosim_trace_file ' can not be read as xml file'],...
                    MsgType.ERROR,...
                    'create_emf_verif_file', '');
                return;
            end
            cocoRoot = DOMNODE.getDocumentElement;
            
            tools_config;
            status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
            UseLusi = true;
            if status
                UseLusi = false;
            end


            data = BUtils.read_json(emf_path);
            nodes = data.nodes;
            emf_nodes_names = fieldnames(nodes)';
            for node_idx =1:numel(emf_nodes_names)
                node_name = emf_nodes_names{node_idx};
                original_name = nodes.(node_name).original_name;
                nl = '\s*\n*';
                vars_names = strcat(nl, '\w+', nl, '(,',nl ,'\w+', nl, ')*');
                vars = strcat('(', vars_names, ':', nl, '(int|real|bool);?)+');
                pattern = strcat(...
                    '(node|function)', nl,...
                    original_name,...
                    nl, '\(',...
                    vars, nl, ...
                    '\)', nl, ...
                    'returns', nl,'\(',...
                    vars,'\);?');
                tokens = regexp(filetext2, pattern,'match') ;
                if ~isempty(tokens)
                    
                    emf_block_name = ...
                        XMLUtils.get_Simulink_block_from_lustre_node_name(...
                        EMF_trace_xml.traceRootNode, ...
                        original_name, ...
                        emf_model_name, ...
                        strcat(emf_model_name, '_PP'));
                    
                    new_node_name = ...
                        XMLUtils.get_lustre_node_from_Simulink_block_name(...
                        cocoRoot, emf_block_name);
                    
                    if ~strcmp(new_node_name, '')
                        if UseLusi
                            main_node_struct = ...
                                LustrecUtils.extract_node_struct(...
                                lus_file_path, original_name, LUSTREC, LUCTREC_INCLUDE_DIR);
                        else
                            main_node_struct = nodes.(node_name);
                        end
                        contract = LustrecUtils.construct_contact(...
                            main_node_struct, new_node_name);
                        
                        
                        filetext2 = strrep(filetext2, tokens{1},...
                            strcat(tokens{1}, '\n', contract));
                        
                        nodes_list{numel(nodes_list) + 1} = original_name;
                    end
                end
            end
            
            
            verif_lus_text = sprintf('%s\n%s\n%s', ...
                filetext1, sep_line, filetext2);
            
            
            fid = fopen(verif_lus_path, 'w');
            fprintf(fid, verif_lus_text);
            fclose(fid);
        end
        
        function contract = construct_contact(node_struct, node_name)
            %inputs
            node_inputs = node_struct.inputs;
            nb_in = numel(node_inputs);
            inputs = cell(nb_in,1);
            for i=1:nb_in
                inputs{i} = node_inputs(i).name;
            end
            inputs = strjoin(inputs, ',');
            
            %outputs
            node_outputs = node_struct.outputs;
            nb_out = numel(node_outputs);
            outputs = cell(nb_out,1);
            for i=1:nb_out
                outputs{i} = node_outputs(i).name;
            end
            outputs = ['(' strjoin(outputs, ',') ')'];
            
            header = '(*@contract\nguarantee';
            
            functions_call_fmt =  '%s = %s(%s);';
            functions_call = sprintf(functions_call_fmt,...
                outputs, node_name, inputs);
            
            contract = sprintf('%s\t%s\n*)',...
                header, functions_call);
        end
        
       
        
        
        %% run Zustre or kind2 on verification file
        
        function [answer, IN_struct, time_max] = run_verif(...
                verif_lus_path,...
                inports, ...
                output_dir,...
                node_name,...
                Backend)
            IN_struct = [];
            time_max = 0;
            answer = '';
            if nargin < 1
                error('Missing arguments to function call: LustrecUtils.run_verif')
            end
            [file_dir, file_name, ~] = fileparts(verif_lus_path);
            if nargin < 3 || isempty(output_dir)
                output_dir = file_dir;
            end
            if nargin < 4 || isempty(node_name)
                node_name = 'top';
            end
            if nargin < 5 || isempty(Backend)
                Backend = 'KIND2';
            end
            timeout = '600';
            cd(output_dir);
            tools_config;
            
            if strcmp(Backend, 'ZUSTRE') || strcmp(Backend, 'Z')
                status = BUtils.check_files_exist(ZUSTRE);
                if status
                    return;
                end
                command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
                    ZUSTRE, verif_lus_path, node_name, timeout);
                display_msg(['ZUSTRE_COMMAND ' command],...
                    MsgType.DEBUG,...
                    'LustrecUtils.run_verif',...
                    '');
                
            elseif strcmp(Backend, 'KIND2') || strcmp(Backend, 'K')
                status = BUtils.check_files_exist(KIND2, Z3);
                if status
                    return;
                end
                command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
                    KIND2, Z3, timeout, node_name, verif_lus_path);
                display_msg(['KIND2_COMMAND ' command],...
                    MsgType.DEBUG, 'LustrecUtils.run_verif', '');
                
            end
            [~, solver_output] = system(command);
            display_msg(...
                solver_output,...
                MsgType.DEBUG,...
                'LustrecUtils.run_verif',...
                '');
            [answer, CEX_XML] = ...
                LustrecUtils.extract_answer(...
                solver_output,...
                Backend,  file_name, node_name,  output_dir);
            if strcmp(answer, 'UNSAFE') && ~isempty(CEX_XML)
                [IN_struct, time_max] =...
                    LustrecUtils.cexTostruct(CEX_XML, node_name, inports);
            end
            
        end
        
        function [answer, CEX_XML] = extract_answer(...
                solver_output,solver, ...
                file_name, ...
                node_name, ...
                output_dir)
            answer = '';
            CEX_XML = [];
            if isempty(solver_output)
                return
            end
            tmp_file = fullfile(...
                output_dir, ...
                strcat(file_name, '_', node_name, '.xml'));
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
            try
                answer = ...
                    property.getElementsByTagName('Answer').item(0).getTextContent;
            catch
                answer = 'ERROR';
            end
            
            if strcmp(solver, 'KIND2') || strcmp(solver, 'JKIND') ...
                    || strcmp(solver, 'K') || strcmp(solver, 'J')
                if strcmp(answer, 'valid')
                    answer = 'SAFE';
                elseif strcmp(answer, 'falsifiable')
                    answer = 'CEX';
                end
            end
            if strcmp(answer, 'CEX')
                answer = 'UNSAFE';
            end
            if strcmp(answer, 'UNSAFE')
                if strcmp(solver, 'JKIND') || strcmp(solver, 'J')
                    xml_cex = xDoc.getElementsByTagName('Counterexample');
                else
                    xml_cex = xDoc.getElementsByTagName('CounterExample');
                end
                if xml_cex.getLength > 0
                    CEX_XML = xml_cex;
                else
                    msg = sprintf('Could not parse counter example from %s', ...
                        solver_output);
                    display_msg(msg, Constants.ERROR, 'Property Checking', '');
                end
            end
            msg = sprintf('Solver Result for file %s of property %s is %s', ...
                file_name, node_name, answer);
            display_msg(msg, Constants.RESULT, 'LustrecUtils.extract_answer', '');
        end
        
        function [IN_struct, time_max] = cexTostruct(...
                cex_xml, ...
                node_name,...
                inports)
            IN_struct = [];
            
            nodes = cex_xml.item(0).getElementsByTagName('Node');
            node = [];
            for idx=0:(nodes.getLength-1)
                if strcmp(nodes.item(idx).getAttribute('name'), node_name)
                    node = nodes.item(idx);
                    break;
                end
            end
            if isempty(node)
                return;
            end
            streams = node.getElementsByTagName('Stream');
            stream_names = {};
            for i=0:(streams.getLength-1)
                s = streams.item(i).getAttribute('name');
                stream_names{i+1} = char(s);
            end
            time_max = 0;
            for i=1:numel(inports)
                IN_struct.signals(i).name = inports(i).name;
                IN_struct.signals(i).datatype = ...
                    LusValidateUtils.get_slx_dt(inports(i).datatype);
                if isfield(inports(i), 'dimensions')
                    IN_struct.signals(i).dimensions = inports(i).dimensions;
                else
                    IN_struct.signals(i).dimensions =  1;
                end
                
                stream_name = inports(i).name;
                stream_index = find(strcmp(stream_names, stream_name), 1);
                if isempty(stream_index)
                    IN_struct.signals(i).values = [];
                else
                    [values, time_step] =...
                        LustrecUtils.extract_values(...
                        streams.item(stream_index-1), inports(i).datatype);
                    IN_struct.signals(i).values = values';
                    time_max = max(time_max, time_step);
                end
            end
            min = -100; max_v = 100;
            for i=1:numel(IN_struct.signals)
                if numel(IN_struct.signals(i).values) < time_max + 1
                    nb_steps = time_max +1 - numel(IN_struct.signals(i).values);
                    dim = IN_struct.signals(i).dimensions;
                    if strcmp(...
                            LusValidateUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                            'bool')
                        values = ...
                            LusValidateUtils.construct_random_booleans(...
                            nb_steps, min, max_v, dim);
                    elseif strcmp(...
                            LusValidateUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                            'int')
                        values = ...
                            LusValidateUtils.construct_random_integers(...
                            nb_steps, min, max_v, IN_struct.signals(i).datatype, dim);
                    elseif strcmp(...
                            IN_struct.signals(i).datatype,...
                            'single')
                        values = ...
                            single(...
                            LusValidateUtils.construct_random_doubles(...
                            nb_steps, min, max_v, dim));
                    else
                        values = ...
                            LusValidateUtils.construct_random_doubles(...
                            nb_steps, min, max_v, dim);
                    end
                    IN_struct.signals(i).values =...
                        [IN_struct.signals(i).values, values];
                end
            end
            IN_struct.time = (0:1:time_max)';
        end
        
        function [values, time_step] = extract_values( stream, dt)
            stream_values = stream.getElementsByTagName('Value');
            for idx=0:(stream_values.getLength-1)
                val = char(stream_values.item(idx).getTextContent);
                if strcmp(val, 'False') || strcmp(val, 'false')
                    values(idx+1) = false;
                elseif strcmp(val, 'True') || strcmp(val, 'true')
                    values(idx+1) = true;
                else
                    values(idx+1) = feval(dt, str2num(val));
                end
            end
            
            time_step = idx;
        end
        
        %% transform input struct to lustre format (inlining values)
        function [lustre_input_values, status] = getLustreInputValuesFormat(...
                input_struct, ...
                nb_steps)
            number_of_inputs = 0;
            status = 0;
            for i=1:numel(input_struct.signals)
                dim = input_struct.signals(i).dimensions;
                
                if numel(dim)==1
                    number_of_inputs = number_of_inputs + nb_steps*dim;
                else
                    number_of_inputs =...
                        number_of_inputs + nb_steps*(prod(dim));
                end
            end
            % Translate input_stract to lustre format (inline the inputs)
            if numel(input_struct.signals)>=1
                lustre_input_values = ones(number_of_inputs,1);
                index = 0;
                for i=0:nb_steps-1
                    for j=1:numel(input_struct.signals)
                        [signal_values, width] = LustrecUtils.inline_array(input_struct.signals(j), i);                        
                        index2 = index + width;
                        lustre_input_values(index+1:index2) = signal_values;
                        index = index2;
                    end
                end
                
            else
                lustre_input_values = ones(1*nb_steps,1);
            end
        end
        
        %% print input_values for lustre binary
        function status = printLustreInputValues(...
                lustre_input_values,...
                output_dir, ...
                file_name)
            values_file = fullfile(output_dir, file_name);
            fid = fopen(values_file, 'w');
            status = 0;
            if fid == -1
                status = 1;
                err = sprintf('can not create file "%s" in directory "%s"',file_name,output_dir);
                display_msg(err, MsgType.ERROR, 'printLustreInputValues', '');
                display_msg(err, MsgType.DEBUG, 'printLustreInputValues', '');
                return;
            end
            for i=1:numel(lustre_input_values)
                value = sprintf('%.60f\n',lustre_input_values(i));
                fprintf(fid, value);
            end
            fclose(fid);
        end
        %% extract lustre outputs from lustre binary
        function status = extract_lustre_outputs(...
                lus_file_name,...
                binary_dir, ...
                node_name,...
                input_file_name,...
                output_file_name)
            PWD = pwd;
            cd(binary_dir);
            lustre_binary = ...
                strcat(lus_file_name,...
                '_',...
                LusValidateUtils.name_format(node_name));
            command  = sprintf('./%s  < %s > %s',...
                lustre_binary, input_file_name, output_file_name);
            [status, binary_out] =system(command);
            if status
                err = sprintf('lustrec binary failed for model "%s"',...
                    lus_file_name,binary_out);
                display_msg(err, MsgType.ERROR, 'extract_lustre_outputs', '');
                display_msg(err, MsgType.DEBUG, 'extract_lustre_outputs', '');
                display_msg(binary_out, MsgType.DEBUG, 'extract_lustre_outputs', '');
                cd(PWD);
                return
            end
        end
        %% compare Simulin outputs and Lustre outputs
        function [valid, error_index, diff_name, diff] = ...
                compare_Simu_outputs_with_Lus_outputs(yout_signals,...
                outputs_array, ...
                eps, ...
                nb_steps)
            diff_name = '';
            diff = 0;
            numberOfOutputs = numel(yout_signals);
            valid = true;
            error_index = 1;
            index_out = 0;
            for i=0:nb_steps-1
                for k=1:numberOfOutputs
                    [yout_values, width] = LustrecUtils.inline_array(yout_signals(k), i);
     
                    for j=1:width
                        index_out = index_out + 1;
                        output_value = ...
                            regexp(outputs_array{index_out},...
                            '\s*:\s*',...
                            'split');
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
                                diff_name =  ...
                                    BUtils.naming_alone(yout_signals(k).blockName);
                                diff_name =  strcat(diff_name, '(',num2str(j), ')');
                                error_index = i+1;
                                break
                            end
                        else
                            warn = sprintf('strange behavour of output %s',...
                                outputs_array{numberOfOutputs*i+k});
                            display_msg(warn,...
                                MsgType.WARNING,...
                                'compare_Simu_outputs_with_Lus_outputs',...
                                '');
                            valid = false;
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
        end
        
        %%
        function [y_inlined, width, status] = inline_array(y_struct, time_step)
            y_inlined = [];
            width = 0;
            status = 0;
            dim = y_struct.dimensions;
            if numel(dim)==1
                y_inlined = y_struct.values(time_step+1,:);
                width = dim;
            elseif numel(dim)==2
                y_inlined = [];
                y = y_struct.values(:,:,time_step+1);
                for idr=1:dim(1)
                    y_inlined = [y_inlined; y(idr,:)'];
                end
                width = dim(1)*dim(2);
            elseif numel(dim)== 3
                y_inlined = [];
                for z=1:dim(3)
                    y = y_struct.values(:,:,z, time_step+1);
                    for idr=1:dim(1)
                        y_inlined = [y_inlined; y(idr,:)'];
                    end
                end
                width = prod(dim);
            else
                display_msg(['We do not support dimension ' num2str(dim)], ...
                    MsgType.ERROR, 'inline_array', '');
                status = 1;
                return;
            end
        end
        
        
        %% Show CEX
        function show_CEX(error_index,...
                input_struct, ...
                yout_signals, ...
                outputs_array )
            numberOfInports = numel(input_struct.signals);
            numberOfOutputs = numel(yout_signals);
            index_out = 0;
            for i=0:error_index-1
                f_msg = sprintf('*****step : %d**********\n',i+1);
                display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                f_msg = sprintf('*****inputs: \n');
                display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                for j=1:numberOfInports
                    [in, width, ~] = LustrecUtils.inline_array(input_struct.signals(j), i);
                    name = input_struct.signals(j).name;
                    for k=1:width
                        f_msg = sprintf('input %s_%d: %f\n',name,k,in(k));
                        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                    end
                end
                
                f_msg = sprintf('*****outputs: \n');
                display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                for k=1:numberOfOutputs
                    [yout_values, width, ~] = LustrecUtils.inline_array(yout_signals(k), i);
                    for j=1:width
                        index_out = index_out + 1;
                        output_value = regexp(outputs_array{index_out},'\s*:\s*','split');
                        if ~isempty(output_value)
                            output_name = output_value{1};
                            output_val = output_value{2};
                            output_val = str2num(output_val(2:end-1));
                            output_name1 =...
                                BUtils.naming_alone(yout_signals(k).blockName);
                            f_msg = sprintf('output %s(%d): %10.16f\n',...
                                output_name1, j, yout_values(j));
                            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                            f_msg = sprintf('Lustre output %s: %10.16f\n',...
                                output_name,output_val);
                            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                        else
                            f_msg = sprintf('strang behavour of output %s',...
                                outputs_array{numberOfOutputs*i+k});
                            display_msg(f_msg, MsgType.WARNING, 'CEX', '');
                            return;
                        end
                    end
                end
                
            end
        end
        
        %% run comparaison
        function [valid,...
                lustrec_failed, ...
                lustrec_binary_failed,...
                sim_failed, ...
                done] = ...
                run_comparaison(slx_file_name, ...
                lus_file_path,...
                node_name, ...
                input_struct,...
                output_dir,...
                input_file_name, ...
                output_file_name, ...
                eps, ...
                show_models)
            
            % define default outputs
            lustrec_failed=0;
            lustrec_binary_failed=0;
            sim_failed=0;
            valid = 0;
            done = 0;
            % define local variables
            OldPwd = pwd;
            if ~isfield(input_struct, 'time')
                msg = sprintf('Variable input_struct need to have a field "time"\n');
                display_msg(msg, MsgType.ERROR, 'validation', '');
                return;
            end
            
            nb_steps = numel(input_struct.time);
            if nb_steps >= 2
                simulation_step = input_struct.time(2) - input_struct.time(1);
            else
                simulation_step = 1;
            end
            stop_time = input_struct.time(end);
            numberOfInports = numel(input_struct.signals);
            
            [~, lus_file_name, ~] = fileparts(char(lus_file_path));
            
            % Copile the lustre code to C
            tools_config;
            status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
            if status
                return;
            end
            err = LustrecUtils.compile_lustre_to_Cbinary(lus_file_path,...
                LusValidateUtils.name_format(node_name), ...
                output_dir, ...
                LUSTREC, LUCTREC_INCLUDE_DIR);
            if err
                lustrec_failed = 1;
                return
            end
            
            % transform input_struct to Lustre format
            [lustre_input_values, status] = ...
                LustrecUtils.getLustreInputValuesFormat(input_struct, nb_steps);
            if status
                lustrec_failed = 1;
                return
            end
            % print lustre inputs in a file
            status = ...
                LustrecUtils.printLustreInputValues(...
                lustre_input_values, output_dir,  input_file_name);
            if status
                lustrec_binary_failed = 1;
                return
            end
            
            
            msg = sprintf('Simulating model "%s"\n',slx_file_name);
            display_msg(msg, MsgType.INFO, 'validation', '');
            GUIUtils.update_status('Simulating model');
            try
                % Simulate the model
                simOut = SLXUtils.simulate_model(slx_file_name, ...
                    input_struct, ...
                    simulation_step,...
                    stop_time,...
                    numberOfInports,...
                    show_models);
                
                % extract lustre outputs from lustre binary
                status = LustrecUtils.extract_lustre_outputs(lus_file_name,...
                    output_dir, ...
                    node_name,...
                    input_file_name, ...
                    output_file_name);
                if status
                    lustrec_binary_failed = 1;
                    cd(OldPwd);
                    return
                end
                
                % compare Simulin outputs and Lustre outputs
                GUIUtils.update_status('Compare Simulink outputs and lustrec outputs');
                
                yout = get(simOut,'yout');
                yout_signals = yout.signals;
                assignin('base','yout',yout);
                assignin('base','yout_signals',yout_signals);
                outputs_array = importdata(output_file_name,'\n');
                [valid, error_index, diff_name, diff] = ...
                    LustrecUtils.compare_Simu_outputs_with_Lus_outputs(yout_signals,...
                    outputs_array, ...
                    eps, ...
                    nb_steps);
                
                
                
                if ~valid
                    %% show the counter example
                    GUIUtils.update_status('Translation is not valid');
                    f_msg = sprintf('translation for model "%s" is not valid \n',slx_file_name);
                    display_msg(f_msg, MsgType.RESULT, 'validation', '');
                    f_msg = sprintf('Here is the counter example:\n');
                    display_msg(f_msg, MsgType.RESULT, 'validation', '');
                    LustrecUtils.show_CEX(...
                        error_index, input_struct, yout_signals, outputs_array );
                    f_msg = sprintf('difference between outputs %s is :%2.10f\n',diff_name, diff);
                    display_msg(f_msg, MsgType.RESULT, 'CEX', '');
                else
                    GUIUtils.update_status('Translation is valid');
                    msg = sprintf('Translation for model "%s" is valid \n',slx_file_name);
                    display_msg(msg, MsgType.RESULT, 'CEX', '');
                end
                cd(OldPwd);
            catch ME
                msg = sprintf('simulation failed for model "%s" :\n%s\n%s',...
                    slx_file_name,ME.identifier,ME.message);
                display_msg(msg, MsgType.ERROR, 'validation', '');
                display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
                sim_failed = 1;
                valid = 0;
                cd(OldPwd);
                return
            end
            done = 1;
        end
        
        
        
    end
    
end


