function [code, dim] = mtimesFun_To_Lustre(x, x_dim, y, y_dim)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    x_reshape = reshape(x, x_dim);
    y_reshape = reshape(y, y_dim);
    
    code={};
    multi = nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY;
    plus = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    
    if prod(x_dim) == 1
        dim = y_dim;
        code = arrayfun(@(z) nasa_toLustre.lustreAst.BinaryExpr(multi, ...
            x, y(z), false), 1:numel(y), 'UniformOutput', 0);
    elseif prod(y_dim) == 1
        dim = x_dim;
        code = arrayfun(@(z) nasa_toLustre.lustreAst.BinaryExpr(multi, ...
            x(z), y, false), 1:numel(x), 'UniformOutput', 0);
    elseif length(x_dim) <= 2 && length(y_dim) <= 2
        
        dim = [x_dim(1), y_dim(2)];
        
        for j=1:x_dim(1)
            for i=1:y_dim(2)
                exp = {};
                for k=0:(x_dim(2)-1)
                    x_ind = mod(i + k, x_dim(2));
                    y_ind = mod(i + k, y_dim(1));
                    if x_ind == 0
                        x_ind = x_dim(2);
                    end
                    if y_ind == 0
                        y_ind = y_dim(1);
                    end
                    ax_indice = [i, x_ind];
                    ay_indice = [y_ind, j];
                    exp{end+1} = nasa_toLustre.lustreAst.BinaryExpr(multi, ...
                        x_reshape(i, x_ind), ...
                        y_reshape(y_ind, j),...
                        false);
                end
                code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(plus, exp);
            end
        end
    else
        
    end
end

