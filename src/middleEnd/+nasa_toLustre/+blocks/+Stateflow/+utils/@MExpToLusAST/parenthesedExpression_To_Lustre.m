function [code, exp_dt] = parenthesedExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    
    [exp, exp_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.expression, parent,...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow);
    code = arrayfun(@(i) ParenthesesExpr(exp{i}), ...
        (1:numel(exp)), 'UniformOutput', false);
    
end