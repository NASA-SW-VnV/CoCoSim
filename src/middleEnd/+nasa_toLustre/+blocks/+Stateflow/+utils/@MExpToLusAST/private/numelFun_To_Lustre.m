function [code, exp_dt] = numelFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    [x, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, '', ...
        isSimulink, isStateFlow, isMatlabFun);    
    code{1} = IntExpr(numel(x));
    exp_dt = 'int';
end

