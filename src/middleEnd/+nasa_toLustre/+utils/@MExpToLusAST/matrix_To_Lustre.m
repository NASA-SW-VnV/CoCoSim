function [code, dt, dim, extra_code] = matrix_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    extra_code = {};
    if isstruct(tree.rows)
        rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
    else
        rows = tree.rows;
    end
    
    nb_rows = numel(rows);
    nb_columns = numel(rows{1});
    if ischar(dt)
        code_dt = arrayfun(@(i) dt, ...
            (1:nb_rows*nb_columns), 'UniformOutput', false);
    elseif iscell(dt) && numel(dt) < nb_rows*nb_columns
        code_dt = arrayfun(@(i) dt{1}, ...
            (1:nb_rows*nb_columns), 'UniformOutput', false);
    else
        code_dt = dt;
    end
    
    code = {};
    code_dt = reshape(code_dt, nb_rows, nb_columns);
    if args.isLeft && nb_columns == 1
        %e.g., [x, y] = f(...)
        for j=1:nb_columns
            for i=1:nb_rows
                v = rows{i}(j);
                args.expected_lusDT = code_dt{i, j};
                [code_i, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    v, args);
                extra_code = MatlabUtils.concat(extra_code, extra_code_i);
                code = MatlabUtils.concat(code, code_i);
            end
        end
        dim = [1 length(code)];
    else
        code_rows = [];
        for i=1:nb_rows
            code_i = [];
            for j=1:nb_columns
                v = rows{i}(j);
                args.expected_lusDT = code_dt{i, j};
                [code_j, ~, code_dim, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    v, args);
                extra_code = MatlabUtils.concat(extra_code, extra_code_i);
                code_j = reshape(code_j, code_dim);
                code_i = [code_i, code_j];
            end
            code_rows = [code_rows; code_i];
        end
        dim = size(code_rows);
        code = reshape(code_rows, 1, numel(code_rows));
    end
    
end
