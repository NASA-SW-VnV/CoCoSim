function [code, exp_dt, dim, extra_code] = invFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [x, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.parameters(1), args);
    vars = nasa_toLustre.utils.MF2LusUtils.addLocalVars(args, exp_dt, prod(dim));
    n = sqrt(numel(x));
    lib_name = sprintf('_inv_M_%dx%d', n, n);
    args.blkObj.addExternal_libraries(strcat('LustMathLib_', lib_name));
    extra_code{1} = nasa_toLustre.lustreAst.LustreEq(vars, ...
        nasa_toLustre.lustreAst.NodeCallExpr(lib_name, x));
    code = vars;
    
end

