function [code, exp_dt, dim] = while_block_To_Lustre(tree, args)
    % end is used for Array indexing: e.g., x(end-1), x(1:end) ... 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global MFUNCTION_EXTERNAL_NODES
    persistent counter;
    if isempty(counter)
        counter = 0;
    end
    
    code = {};
    exp_dt = '';
    dim = [];
    
    %%
    IDs = modifiedVars(tree);
    if isempty(IDs)
        return;
    end
    data_set = args.data_map.values();
    data_set = data_set(cellfun(@(x) ismember(x.Name, IDs), data_set));
    if isempty(data_set)
        return;
    end
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    node_outputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(data_set);
    counter = counter + 1;
    node_name = sprintf('%s_abstract_while_loop_%d', ...
        nasa_toLustre.utils.SLX2LusUtils.node_name_format(args.blk), counter);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('While code is abstracted inside Matlab Function block: %s\n The code is the following :\n%s',...
        args.blk.Origin_path, tree.text), true);
    while_node = nasa_toLustre.lustreAst.LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false, true);
    MFUNCTION_EXTERNAL_NODES{end+1} = while_node;
    [call, oututs_Ids] = while_node.nodeCall();
    if length(oututs_Ids) == 1
    code{1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
    else
        code{1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.TupleExpr(oututs_Ids), call);
    end
end

function IDs = modifiedVars(tree)
    IDs = {};
    if isstruct(tree.statements)
        tree_statements = arrayfun(@(x) x, tree.statements, 'UniformOutput', 0);
    else
        tree_statements = tree.statements;
    end
    for i=1:length(tree_statements)
        if strcmp(tree_statements{i}.type, 'assignment')
            IDs = MatlabUtils.concat(IDs, symvar(tree_statements{i}.leftExp.text));
        elseif isfield(tree_statements{i}, 'statements')
            IDs = MatlabUtils.concat(IDs, modifiedVars(tree_statements{i}));
        end
    end
end