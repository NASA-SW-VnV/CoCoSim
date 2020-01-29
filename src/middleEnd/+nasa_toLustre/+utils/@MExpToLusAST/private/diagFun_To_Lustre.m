function [code, exp_dt, dim, extra_code] = diagFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    dim = [];
    code = {};
    [x, exp_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if length(tree.parameters) > 1
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function diag in expression "%s" do not support a 2nd argument.',...
                tree.text);
            throw(ME);
    elseif prod(x_dim) > max(x_dim) % if is a matrix and not a vector
        dim = [min(x_dim) 1];
        x = reshape(x, x_dim);
        for i=1:dim(1)
            code{end + 1} = x(i, i);
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
        if isrow(r_code), r_code = r_code'; end
        r_code = reshape(r_code, dim);
        for i=1:prod(x_dim)
            r_code(i, i) = x(i);
        end
        code = reshape(r_code, [prod(dim) 1]);
    end
    
end