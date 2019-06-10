%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% compositional verification file between EMF and cocosim
function [verif_lus_path, nodes_list] = create_emf_verif_file(...
        lus_file_path,...
        coco_lus_fpath,...
        emf_path, ...
        EMF_trace_xml, ...
        toLustre_Trace_xml)
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
                SLX2Lus_Trace.get_Simulink_block_from_lustre_node_name(...
                EMF_trace_xml, ...
                original_name, ...
                emf_model_name, ...
                strcat(emf_model_name, '_PP'));

            new_node_name = ...
                SLX2Lus_Trace.get_lustre_node_from_Simulink_block_name(...
                toLustre_Trace_xml, emf_block_name);

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

