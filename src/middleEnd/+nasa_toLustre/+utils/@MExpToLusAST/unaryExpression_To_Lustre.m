function [code, exp_dt, dim, extra_code] = unaryExpression_To_Lustre(tree, args)
    %     unaryOperator :   '&' | '*' | '+' | '-' | '~' | '!'
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        
        
    
    
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
        tree, args);
    args.expected_lusDT = exp_dt;
    [right, ~, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    if strcmp(tree.operator, '~') || strcmp(tree.operator, '!')
        op = nasa_toLustre.lustreAst.UnaryExpr.NOT;
    elseif strcmp(tree.operator, '-')
        op = nasa_toLustre.lustreAst.UnaryExpr.NEG;
    elseif strcmp(tree.operator, '+')
        code = right;
        return;
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" with operator "%s" is not support. Work in progress!',...
            tree.text, tree.operator);
        throw(ME);
    end
    code = arrayfun(@(i) nasa_toLustre.lustreAst.UnaryExpr(op, right{i}, false), ...
        (1:numel(right)), 'UniformOutput', false);
    
end
