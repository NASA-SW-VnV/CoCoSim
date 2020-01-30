function [outputs, inputs] = getInOutputsFromAction(lus_action, isCondition, data_map, expression, isMatlab)

    
    if nargin < 5 || isempty(isMatlab)
        isMatlab = false;
    end
    outputs = {};
    inputs = {};
    
    if numel(lus_action) == 1 && isa(lus_action{1}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
        assignments = lus_action{1}.getAssignments();
    else
        assignments = lus_action;
    end
    for act_idx=1:numel(assignments)
        if ~isCondition
            if isa(assignments{act_idx}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
                [outputs_i, inputs_i] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(...
                    assignments(act_idx), isCondition, data_map, expression);
                outputs = MatlabUtils.concat(outputs, outputs_i);
                inputs = MatlabUtils.concat(inputs, inputs_i);
                continue;
            elseif~isa(assignments{act_idx}, 'nasa_toLustre.lustreAst.LustreEq')
                if isMatlab
                    continue;
                end
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" should be an assignement (e.g. outputs = f(inputs))', ...
                    expression);
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
                lusDT = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, k);
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(k, lusDT);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for action "%s"', ...
                    k, expression);
                throw(ME);
            end
        end
        for i=1:numel(inputs_names)
            k = inputs_names{i};
            if isKey(data_map, k)
                inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(k, data_map(k).LusDatatype);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for Action "%s"', ...
                    k, expression);
                throw(ME);
            end
        end
    end
end
