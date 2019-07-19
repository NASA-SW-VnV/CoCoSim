function [code, dt, dim] = matrix_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree, args);
    
    if isstruct(tree.rows)
        rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
    else
        rows = tree.rows;
    end
    
    nb_rows = numel(rows);
    nb_culomns = numel(rows{1});
    dim = [nb_rows, nb_culomns];
    if ischar(dt)
        code_dt = arrayfun(@(i) dt, ...
            (1:nb_rows*nb_culomns), 'UniformOutput', false);
    elseif iscell(dt) && numel(dt) < nb_rows*nb_culomns
        code_dt = arrayfun(@(i) dt{1}, ...
            (1:nb_rows*nb_culomns), 'UniformOutput', false);
    else
        code_dt = dt;
    end
    
    code = {};
    code_dt = reshape(code_dt, nb_rows, nb_culomns);
    for i=1:nb_rows
        columns = rows{i};
        for j=1:numel(columns)
            args.expected_lusDT = code_dt{i, j};
            code(end+1) =...
                nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(...
                columns(j), args);
        end
    end
    
    
end
