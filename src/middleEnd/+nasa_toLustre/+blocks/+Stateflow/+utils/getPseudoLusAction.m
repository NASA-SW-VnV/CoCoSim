function [lus_action, outputs, inputs, external_libraries] = ...
        getPseudoLusAction(expreession, data_map, isCondition, action_parentPath, ignoreOutInputs)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if nargin < 3
        isCondition = false;
    end
    if nargin < 5
        ignoreOutInputs = false;
    end
    outputs = {};
    inputs = {};
    
    obj = DummyBlock_To_Lustre();
    blk.Origin_path = action_parentPath;
    [lus_action, status] = ...
        MExpToLusAST.translate(obj, expreession, [], blk, ...
        data_map, [], '', false, true);
    if status
        ME = MException('COCOSIM:STATEFLOW', ...
            'ParseError: unsupported Action %s in StateFlow.', expreession);
        throw(ME);
    end
    external_libraries = obj.getExternalLibraries();
    
    if isempty(lus_action)
        return;
    end
    [outputs, inputs] = getInOutputs(lus_action, isCondition, ignoreOutInputs, data_map, expreession);
end

function [outputs, inputs] = getInOutputs(lus_action, isCondition, ignoreOutInputs, data_map, action)
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
                [outputs_i, inputs_i] = getInOutputs(assignments(act_idx));
                outputs = MatlabUtils.concat(outputs, outputs_i);
                inputs = MatlabUtils.concat(inputs, inputs_i);
                continue;
            elseif~isa(assignments{act_idx}, 'LustreEq')
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" in "%s" should be an assignement (e.g. outputs = f(inputs))', ...
                    action, action_parentPath);
                throw(ME);
            end
        end
        %ignoreOutInputs flag is used by unitTests.
        if ignoreOutInputs
            return;
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
                    k, action);
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
                    k, action);
                throw(ME);
            end
        end
    end
end