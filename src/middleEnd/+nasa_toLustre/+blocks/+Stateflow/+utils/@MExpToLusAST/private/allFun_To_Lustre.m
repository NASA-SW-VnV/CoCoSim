function [code, exp_dt] = allFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    [x, x_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, 'bool', ...
        isSimulink, isStateFlow, isMatlabFun);
    x = MExpToLusDT.convertDT(BlkObj, x, x_dt, 'bool');
    op = BinaryExpr.AND;
    
    code{1} = BinaryExpr.BinaryMultiArgs(op, x);
    exp_dt = 'bool';
end

