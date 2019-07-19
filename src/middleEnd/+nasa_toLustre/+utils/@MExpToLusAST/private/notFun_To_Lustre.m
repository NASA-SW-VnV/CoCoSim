function [code, exp_dt, dim] = notFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    op = nasa_toLustre.lustreAst.UnaryExpr.NOT;
    args.expected_lusDT = 'bool';
    [right, ~, dim] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    code = arrayfun(@(i) nasa_toLustre.lustreAst.UnaryExpr(op, right{i}, false), ...
        (1:numel(right)), 'UniformOutput', false);
    exp_dt = 'bool';
    
end

