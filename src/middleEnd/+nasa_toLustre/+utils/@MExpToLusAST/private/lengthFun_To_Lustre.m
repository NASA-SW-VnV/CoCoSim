function [code, exp_dt, dim, extra_code] = lengthFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    dim = [1 1];
    code = {};
    [~, ~, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if strcmp(args.expected_lusDT, 'real')
        code{1} = nasa_toLustre.lustreAst.RealExpr(max(x_dim));
        exp_dt = 'real';
    else
        code{1} = nasa_toLustre.lustreAst.IntExpr(max(x_dim));
        exp_dt = 'int';
    end

end

