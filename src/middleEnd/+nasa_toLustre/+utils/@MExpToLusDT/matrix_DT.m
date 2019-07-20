function [lusDT, slxDT] = matrix_DT(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if isempty(tree.rows)
        lusDT = '';
        slxDT = '';
        return;
    end
    if isstruct(tree.rows)
        rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
    else
        rows = tree.rows;
    end
    if args.isLeft
        % the following code is for the function outputs :
        % e.g., "function [y, z] = f(x)"
        nb_rows = numel(rows);
        nb_culomns = numel(rows{1});
        if nb_rows > 1
            % it does not make sens to have a matrix on the left of an equation
            % e.g., "function [y, z] = f(x)"
            lusDT = '';
            slxDT = '';
            return;
        end
        lusDT = cell(nb_culomns,1);
        slxDT = cell(nb_culomns,1);
        columns = rows{1};
        for j=1:numel(columns)
            [lusDT_i, slxDT_i] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                columns(j), args);
            lusDT{j} = lusDT_i;
            slxDT{j} = slxDT_i;
        end
    else
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(rows{1}(1), ...
            args);
    end
end

