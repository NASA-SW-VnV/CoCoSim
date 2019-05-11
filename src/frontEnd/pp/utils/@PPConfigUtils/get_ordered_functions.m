function ordered_functions = get_ordered_functions(fcts_map)
    % priority -> functions
    priority_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    for k= fcts_map.keys
        priority = fcts_map(k{1});
        if isKey(priority_map, priority)
            priority_map(priority) = [priority_map(priority), k];
        else
            priority_map(priority) = k;
        end
    end

    % order functions by priority and remove functions with -1 priority
    ordered_functions = {};
    keys = setdiff(sort(cell2mat(priority_map.keys)), -1);
    if isempty(keys)
        return;
    end
    for key= keys
        v_list = priority_map(key);
        for i=1:numel(v_list)
            ordered_functions{numel(ordered_functions) + 1} = v_list{i};
        end

    end

end
 