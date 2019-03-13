%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function min_max_constraints = constructInportsMinMaxConstraints(model_full_path, IMIN_DEFAULT, IMAX_DEFAULT)

    [~, model_name, ~] = fileparts(char(model_full_path));
    if ~bdIsLoaded(model_name)
        load_system(model_full_path);
    end
    block_paths = find_system(model_name, 'SearchDepth',1, 'BlockType', 'Inport');
    min_max_constraints = cell(numel(block_paths), 1);
    for i=1:numel(block_paths)
        min_max_constraints{i} = cell(3,1);
        block = block_paths{i};
        min_max_constraints{i}{1} = get_param(block, 'Name');
        outMin = get_param(block, 'OutMin');
        outMax = get_param(block, 'OutMax');
        if isequal(outMin, '[]') ...
                || isequal(outMax, '[]')
            min_max_constraints{i}{2} = IMIN_DEFAULT;
            min_max_constraints{i}{3} = IMAX_DEFAULT;
        else
            min_max_constraints{i}{2} = str2num(outMin);
            min_max_constraints{i}{3} = str2num(outMax);
        end
    end
end
