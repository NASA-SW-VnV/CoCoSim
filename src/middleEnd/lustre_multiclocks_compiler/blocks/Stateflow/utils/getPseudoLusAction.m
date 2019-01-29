function [lus_action, outputs, inputs, external_libraries] = ...
        getPseudoLusAction(action, data_map, isCondition, action_parentPath, ignoreOutInputs)
    
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
        Exp2Lus.expToLustre(obj, action, [], blk, [], ...
        data_map, '', true);
    if status
        ME = MException('COCOSIM:STATEFLOW', ...
            'ParseError: unsupported Action %s in StateFlow.', action);
        throw(ME);
    end
    external_libraries = obj.getExternalLibraries();
    
    if isempty(lus_action)
        return;
    end
    for act_idx=1:numel(lus_action)
        if ~isCondition && ~isa(lus_action{act_idx}, 'LustreEq')
            ME = MException('COCOSIM:STATEFLOW', ...
                'Action "%s" in "%s" should be an assignement (e.g. outputs = f(inputs))', ...
                action, action_parentPath);
            throw(ME);
        end
        %ignoreOutInputs flag is used by unitTests.
        if ignoreOutInputs
            return;
        end
        if isCondition
            inputs_names = lus_action{act_idx}.GetVarIds();
            outputs_names = {};
        else
            [outputs_names, inputs_names] = lus_action{act_idx}.GetVarIds();
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