function [code, exp_dt] = sumFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    op = BinaryExpr.PLUS;
    if length(tree.parameters) == 1
        [x, x_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
        code{1} = BinaryExpr.BinaryMultiArgs(op, x);
    else
        %TODO support "sum(X,DIM)" sums along the dimension DIM. 
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function sum in expression "%s" has more than one argument is not supported.',...
            tree.text);
        throw(ME);
    end
    exp_dt = x_dt;
end

