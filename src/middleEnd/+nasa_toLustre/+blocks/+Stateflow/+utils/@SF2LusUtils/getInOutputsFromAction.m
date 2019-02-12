function [outputs, inputs] = getInOutputsFromAction(lus_action, isCondition, data_map, expreession)
    import nasa_toLustre.lustreAst.*
    outputs = {};
    inputs = {};
    
    if numel(lus_action) == 1 && isa(lus_action{1}, 'ConcurrentAssignments')
        assignments = lus_action{1}.getAssignments();
    else
        assignments = lus_action;
    end
    for act_idx=1:numel(assignments)
        if ~isCondition
            if isa(assignments{act_idx}, 'ConcurrentAssignments')
                [outputs_i, inputs_i] = getInOutputsFromAction(assignments(act_idx));
                outputs = MatlabUtils.concat(outputs, outputs_i);
                inputs = MatlabUtils.concat(inputs, inputs_i);
                continue;
            elseif~isa(assignments{act_idx}, 'LustreEq')
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" in "%s" should be an assignement (e.g. outputs = f(inputs))', ...
                    expreession, action_parentPath);
                throw(ME);
            end
        end
        
        if isCondition
            inputs_names = assignments{act_idx}.GetVarIds();
            outputs_names = {};
        else
            [outputs_names, inputs_names] = assignments{act_idx}.GetVarIds();
        end
        outputs_names = unique(outputs_names);
        inputs_names = unique(inputs_names);
        
        for i=1:numel(outputs_names)
            k = outputs_names{i};
            if isKey(data_map, k)
                outputs{end + 1} = LustreVar(k, data_map(k).LusDatatype);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for action "%s"', ...
                    k, expreession);
                throw(ME);
            end
        end
        for i=1:numel(inputs_names)
            k = inputs_names{i};
            if isKey(data_map, k)
                inputs{end + 1} = LustreVar(k, data_map(k).LusDatatype);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for Action "%s"', ...
                    k, expreession);
                throw(ME);
            end
        end
    end
end