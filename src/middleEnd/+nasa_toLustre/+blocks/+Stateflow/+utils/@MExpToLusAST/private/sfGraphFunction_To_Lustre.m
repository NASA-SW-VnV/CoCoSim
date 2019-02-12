function code = sfGraphFunction_To_Lustre(obj, tree, parent, ...
        blk, data_map, ~, ~, isSimulink, isStateFlow, isMatlabFun)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    global SF_GRAPHICALFUNCTIONS_MAP SF_STATES_NODESAST_MAP;
    func = SF_GRAPHICALFUNCTIONS_MAP(tree.ID);
    
    if isa(tree.parameters, 'struct')
        parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
    else
        parameters = tree.parameters;
    end
    sfNodename = SF2LusUtils.getUniqueName(func);
    actionNodeAst = SF_STATES_NODESAST_MAP(sfNodename);
    node_inputs = actionNodeAst.getInputs();
    if isempty(parameters)
        [call, ~] = actionNodeAst.nodeCall();
        code = call;
    elseif numel(node_inputs) == numel(parameters)
        params_dt =  {};
        for i=1:numel(node_inputs)
            d = node_inputs{i};
            params_dt{end+1} = d.getDT();
        end
        args = cell(numel(parameters), 1);
        for i=1:numel(parameters)
            [args(i), ~] = ...
                MExpToLusAST.expression_To_Lustre(obj, parameters{i}, ...
                parent, blk, data_map, node_inputs, params_dt{i}, isSimulink,...
                isStateFlow, isMatlabFun);
        end
        code = NodeCallExpr(sfNodename, args);
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" expected %d parameters but got %d',...
            tree.ID, numel(node_inputs), numel(tree.parameters));
        throw(ME);
    end
    
end