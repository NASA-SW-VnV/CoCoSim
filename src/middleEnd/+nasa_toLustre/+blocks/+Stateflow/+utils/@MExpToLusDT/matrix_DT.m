function dt = matrix_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    if isempty(tree.rows)
        dt = '';
        return;
    end
    if isstruct(tree.rows)
        rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
    else
        rows = tree.rows;
    end
    nb_rows = numel(rows);
    nb_culomns = numel(rows{1});
    dt = cell(nb_rows, nb_culomns);
    for i=1:nb_rows
        columns = rows{i};
        for j=1:numel(columns)
            dt{i, j} = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(columns(j), data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        end
    end
    dt = reshape(dt, [nb_rows * nb_culomns, 1]);
end

