function [code, exp_dt, dim, extra_code] = diagFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    dim = [];
    [x, exp_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if length(tree.parameters) > 1
        if prod(x_dim) > max(x_dim)
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function diag in expression "%s" do not support a 2nd argument.',...
                tree.text);
            throw(ME);
        end
    else
        dim = [max(x_dim) max(x_dim)];
        if strcmp(exp_dt, 'int')
            r_code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(0), (1:prod(dim)), 'UniformOutput', 0);
            exp_dt = 'int';
        else
            r_code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(0), (1:prod(dim)), 'UniformOutput', 0);
            exp_dt = 'real';
        end
        r_code = reshape(r_code, dim);
        for i=1:prod(x_dim)
            r_code(i, i) = x(i);
        end
        code = reshape(r_code, 1, prod(dim));
    end
    
end