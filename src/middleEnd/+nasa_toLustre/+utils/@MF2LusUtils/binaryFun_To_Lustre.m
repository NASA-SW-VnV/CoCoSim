function [code, exp_dt, dim, extra_code] = binaryFun_To_Lustre(tree, args, op)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    code = {};
    [x, x_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    [y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
    extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    
    [x, y] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(x, y, tree);
    
    for i=1:numel(x)
        code{end+1} = nasa_toLustre.lustreAst.BinaryExpr(op, ...
            x(i), ...
            y(i),...
            false);
    end
    dim = x_dim;
    exp_dt = x_dt;
    
end