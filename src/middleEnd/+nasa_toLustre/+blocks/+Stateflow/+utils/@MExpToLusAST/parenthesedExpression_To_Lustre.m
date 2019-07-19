function [code, exp_dt, dim] = parenthesedExpression_To_Lustre(BlkObj, tree, ...
    parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun, if_cond)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        
    
    [exp, exp_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.expression, parent,...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun, if_cond);
    code = arrayfun(@(i) nasa_toLustre.lustreAst.ParenthesesExpr(exp{i}), ...
        (1:numel(exp)), 'UniformOutput', false);
    
end
