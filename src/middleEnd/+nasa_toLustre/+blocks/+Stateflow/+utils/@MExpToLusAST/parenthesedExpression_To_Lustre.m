function [code, exp_dt] = parenthesedExpression_To_Lustre(BlkObj, tree, ...
    parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    
    [exp, exp_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.expression, parent,...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
    code = arrayfun(@(i) ParenthesesExpr(exp{i}), ...
        (1:numel(exp)), 'UniformOutput', false);
    
end