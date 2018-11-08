function [lus_action, outputs, inputs, external_libraries] = getPseudoLusAction(action, isCondition, ignoreOutInputs)
    global SF_DATA_MAP;
    if nargin < 2
        isCondition = false;
    end
    if nargin < 3
        ignoreOutInputs = false;
    end
    outputs = {};
    inputs = {};
    
    obj = DummyBlock_To_Lustre();
    [lus_action, status] = ...
        Exp2Lus.expToLustre(obj, action, [], [], [], ...
        SF_DATA_MAP, '', true);
    if status
        ME = MException('COCOSIM:STATEFLOW', ...
            'ParseError: unsupported Action %s in StateFlow.', action);
        throw(ME);
    end
    external_libraries = obj.getExternalLibraries();
    
    if isempty(lus_action) 
        return;
    end
    if isa(lus_action, 'NodeCallExpr')
        %TODO Stateflow functions. Switch it to LustreEq
        
    end
    if ~isCondition && ~isa(lus_action, 'LustreEq')
        ME = MException('COCOSIM:STATEFLOW', ...
            'Action "%s" should be an assignement (e.g. outputs = f(inputs))', action);
        throw(ME);
    end
    %this flag is used by unitTests.
    if ignoreOutInputs
        return;
    end
    if isCondition
        inputs_names = lus_action.GetVarIds();
        outputs_names = {};
    else
        [outputs_names, inputs_names] = lus_action.GetVarIds();
    end
    outputs_names = unique(outputs_names);
    inputs_names = unique(inputs_names);
    
    for i=1:numel(outputs_names)
        k = outputs_names{i};
        if isKey(SF_DATA_MAP, k)
            outputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).LusDatatype);
        else
            ME = MException('COCOSIM:STATEFLOW', ...
                'Variable %s can not be found for state "%s"', ...
                k, state.Path);
            throw(ME);
        end
    end
    for i=1:numel(inputs_names)
        k = inputs_names{i};
        if isKey(SF_DATA_MAP, k)
            inputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).LusDatatype);
        else
            ME = MException('COCOSIM:STATEFLOW', ...
                'Variable %s can not be found for Action "%s"', ...
                k, action);
            throw(ME);
        end
    end
end