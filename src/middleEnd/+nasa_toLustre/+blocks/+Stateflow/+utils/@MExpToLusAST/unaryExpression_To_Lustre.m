function [code, exp_dt] = unaryExpression_To_Lustre(BlkObj, tree, parent,...
    blk, data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %     unaryOperator :   '&' | '*' | '+' | '-' | '~' | '!'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    right = MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent,...
        blk, data_map, inputs, exp_dt, isSimulink, isStateFlow, isMatlabFun);
    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
        op = UnaryExpr.NOT;
    elseif isequal(tree.operator, '-')
        op = nasa_toLustre.lustreAst.UnaryExpr.NEG;
    elseif isequal(tree.operator, '+')
        code = right;
        return;
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" with operator "%s" is not support. Work in progress!',...
            tree.text, tree.operator);
        throw(ME);
    end
    code = arrayfun(@(i) UnaryExpr(op, right{i}, false), ...
        (1:numel(right)), 'UniformOutput', false);
    
end