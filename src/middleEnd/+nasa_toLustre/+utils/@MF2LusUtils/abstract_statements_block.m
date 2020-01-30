function [while_node] = abstract_statements_block(tree, args, type)
    %ABSTRACT_STATEMENTS_BLOCK abstract WHILE, FOR and SWITCH blocks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    persistent counter;
    if isempty(counter)
        counter = 0;
    end
    while_node = {};
    IDs = modifiedVars(tree);
    if isempty(IDs)
        return;
    end
    data_set = args.data_map.values();
    data_set = data_set(cellfun(@(x) ismember(x.Name, IDs), data_set));
    if isempty(data_set)
        return;
    end
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(),...
        'bool');
    node_outputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(data_set);
    counter = counter + 1;
    node_name = sprintf('%s_abstract_%s_%d', ...
        nasa_toLustre.utils.SLX2LusUtils.node_name_format(args.blk), type, ...
        counter);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('%s code is abstracted inside Matlab Function block: %s\n The code is the following :\n%s',...
        type, args.blk.Origin_path, tree.text), true);
    while_node = nasa_toLustre.lustreAst.LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false, true);
end

function IDs = modifiedVars(tree)
    IDs = {};
    if isfield(tree, 'statements')
        tree = tree.statements;
    end
    if isstruct(tree)
        tree_statements = arrayfun(@(x) x, tree, 'UniformOutput', 0);
    else
        tree_statements = tree;
    end
    for i=1:length(tree_statements)
        if strcmp(tree_statements{i}.type, 'assignment')
            IDs = MatlabUtils.concat(IDs, ...
                nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree_statements{i}));
        elseif isfield(tree_statements{i}, 'statements')
            IDs = MatlabUtils.concat(IDs, modifiedVars(tree_statements{i}));
        end
    end
end