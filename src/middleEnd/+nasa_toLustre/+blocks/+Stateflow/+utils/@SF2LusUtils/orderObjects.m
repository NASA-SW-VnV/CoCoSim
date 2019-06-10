function ordered = orderObjects(objects, fieldName)
    %% Order states, transitions ...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin == 1
        fieldName = 'Path';
    end
    if strcmp(fieldName, 'Path')
        levels = cellfun(@(x) numel(regexp(x.Path, '/', 'split')), ...
            objects, 'UniformOutput', true);
        [~, I] = sort(levels, 'descend');
        ordered = objects(I);
    elseif strcmp(fieldName, 'ExecutionOrder') ...
            || strcmp(fieldName, 'Port')
        orders = cellfun(@(x) x.(fieldName), ...
            objects, 'UniformOutput', true);
        [~, I] = sort(orders);
        ordered = objects(I);
    end
end
