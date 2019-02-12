
%% Order states, transitions ...
function ordered = orderObjects(objects, fieldName)
    if nargin == 1
        fieldName = 'Path';
    end
    if isequal(fieldName, 'Path')
        levels = cellfun(@(x) numel(regexp(x.Path, '/', 'split')), ...
            objects, 'UniformOutput', true);
        [~, I] = sort(levels, 'descend');
        ordered = objects(I);
    elseif isequal(fieldName, 'ExecutionOrder') ...
            || isequal(fieldName, 'Port')
        orders = cellfun(@(x) x.(fieldName), ...
            objects, 'UniformOutput', true);
        [~, I] = sort(orders);
        ordered = objects(I);
    end
end
