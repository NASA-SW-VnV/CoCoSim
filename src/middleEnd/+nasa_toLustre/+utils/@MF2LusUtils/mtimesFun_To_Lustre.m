function [code, dim] = mtimesFun_To_Lustre(x, x_dim, y, y_dim)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
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
        
        x_reshape = reshape(x, x_dim);
        y_reshape = reshape(y, y_dim);
        
        dim = [x_dim(1), y_dim(2)];
        code_matrix = cell(x_dim(1), y_dim(2));
        for i=1:x_dim(1)
            for j=1:y_dim(2)
                exp = {};
                for k=1:x_dim(2)
                    exp{end+1} = nasa_toLustre.lustreAst.BinaryExpr(multi, ...
                        x_reshape(i, k), ...
                        y_reshape(k, j),...
                        false);
                end
                code_matrix(i,j) = {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(plus, exp)};
            end
        end
        code = reshape(code_matrix, [1, numel(code_matrix)]);
    else
        % TODO for francois
    end
end

