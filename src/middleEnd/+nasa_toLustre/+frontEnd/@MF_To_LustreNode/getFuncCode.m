function [fun_node,failed ]  = getFuncCode(func, data_map, blkObj, parent, blk)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    
    statements = func.statements;
    expected_dt = '';
    isSimulink = false;
    isStateFlow = false;
    isMatlabFun = true;
    variables = {};
    body = {};
    failed = false;
    
    
    
    for i=1:length(statements)
        if isstruct(statements)
            s = statements(i);
        else
            s = statements{i};
        end
        try
            lusCode = MExpToLusAST.expression_To_Lustre(blkObj, s,...
                parent, blk, data_map, {}, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            [vars, ~] = SF2LusUtils.getInOutputsFromAction(lusCode, ...
                false, data_map, s.text);
            variables = MatlabUtils.concat(variables, vars);
            body = MatlabUtils.concat(body, lusCode);
        catch me
            if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                display_msg(me.message, MsgType.WARNING, 'getMFunctionCode', '');
            else
                display_msg(me.getReport(), MsgType.DEBUG, 'getMFunctionCode', '');
            end
            display_msg(sprintf('Statement "%s" failed for block %s', ...
                s.text, HtmlItem.addOpenCmd(blk.Origin_path)),...
                MsgType.WARNING, 'getMFunctionCode', '');
            failed = true;
        end
    end
    [fun_node] = MF_To_LustreNode.getFunHeader(func, blk, data_map);
    node_outputs = fun_node.getOutputs();
    variables = LustreVar.uniqueVars(variables);
    variables = LustreVar.setDiff(variables, node_outputs);
    fun_node.setLocalVars(variables);
    fun_node.setBodyEqs(body);
    fun_node = fun_node.pseudoCode2Lustre();
end