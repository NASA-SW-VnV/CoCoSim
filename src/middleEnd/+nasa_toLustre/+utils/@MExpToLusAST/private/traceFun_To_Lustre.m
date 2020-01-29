function [code, exp_dt, dim, extra_code] = traceFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    plus = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    [x, exp_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    x = reshape(x, x_dim);
    diag = {};
    for i=1:min(x_dim)
        diag{end+1} = x{i, i};
    end
    code = {};
    code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(plus, diag);
    
    dim = [1 1];
end
    
