function [lus_action, outputs, inputs, external_libraries] = getPseudoLusAction(action, isCondition, ignoreOutInputs)
    if nargin < 2
        isCondition = false;
    end
    if nargin < 3
        ignoreOutInputs = false;
    end
    action = strrep(action, ';', '');
    [tree, status, unsupportedExp] = Fcn_Exp_Parser.parse(action);
    outputs = {};
    inputs = {};
    if status
        ME = MException('COCOSIM:STATEFLOW', ...
            'ParseError: unsupported expression "%s" in Action %s in StateFlow.', ...
            unsupportedExp, action);
        throw(ME);
    end
    obj = DummyBlock_To_Lustre();
    try
        lus_action = Fcn_To_Lustre.tree2code(obj, tree, [], [], [], [], true);
        external_libraries = obj.getExternalLibraries();
    catch me
        if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
            ME = MException('COCOSIM:STATEFLOW', ...
                '%s in Action %s', ...
                me.message, action);
            throw(ME);
        else
            display_msg(me.getReport(), MsgType.DEBUG, 'getPseudoLusAction', '');
            ME = MException('COCOSIM:STATEFLOW', ...
                'Parsing Action "%s" has failed', action);
            throw(ME);
        end
    end
    if isempty(lus_action)
        return;
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
    global SF_DATA_MAP;
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