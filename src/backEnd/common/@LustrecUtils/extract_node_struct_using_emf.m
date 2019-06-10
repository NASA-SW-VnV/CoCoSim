%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [main_node_struct, ...
        status] = extract_node_struct_using_emf(...
        lus_file_path,...
        main_node_name,...
        LUSTREC, ...
        LUCTREC_INCLUDE_DIR)
    main_node_struct = [];
    [contract_path, status] = LustrecUtils.generate_emf(...
        lus_file_path, '', LUSTREC, '', LUCTREC_INCLUDE_DIR);

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

