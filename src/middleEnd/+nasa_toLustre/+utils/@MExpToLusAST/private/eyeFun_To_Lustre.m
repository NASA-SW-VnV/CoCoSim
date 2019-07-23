function [code, exp_dt, dim] = eyeFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if length(tree.parameters) == 1
        expr = sprintf("zeros(%s)", tree.parameters.text);
    else
        expr = sprintf("zeros(%s, %s)", tree.parameters.text);
    end
    new_tree = MatlabUtils.getExpTree(expr);
    [r_code, exp_dt, dim] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    if prod(dim) > 1
        r_code = reshape(r_code, dim);
    end
    
    if strcmp(exp_dt, 'int')
        one = nasa_toLustre.lustreAst.IntExpr(1);
    else
        one = nasa_toLustre.lustreAst.RealExpr(1);
    end
    
    for i=1:min(dim)
        r_code{i, i} = one;
    end
    
    code = reshape(r_code, 1, prod(dim));
end