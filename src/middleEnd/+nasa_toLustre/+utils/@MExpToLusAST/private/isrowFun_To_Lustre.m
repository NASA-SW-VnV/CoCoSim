function [code, exp_dt, dim, extra_code] = isrowFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    code = {};
    [~, exp_dt, X_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    if (X_dim(1) == 1 && X_dim(2) > 0)
        code{1} = nasa_toLustre.lustreAst.BoolExpr(true);
    else
        code{1} = nasa_toLustre.lustreAst.BoolExpr(false);
    end
    
    dim = [1 1];
end

