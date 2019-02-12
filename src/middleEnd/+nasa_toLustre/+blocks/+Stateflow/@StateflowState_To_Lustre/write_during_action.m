%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DURING ACTION
function [main_node, external_libraries] = ...
        write_during_action(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP;
    external_libraries = {};
    main_node = {};
    body = {};
    outputs = {};
    inputs = {};

    parentName = fileparts(state.Path);
    if isempty(parentName)
        %main chart
        return;
    end

    %actions code
    actions = SFIRPPUtils.split_actions(state.Actions.During);
    nb_actions = numel(actions);

    for i=1:nb_actions
        try
            [actions_i, outputs_i, inputs_i, external_libraries_i] = ...
                getPseudoLusAction(actions{i}, data_map, false, state.Path);
            body = [body, actions_i];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            external_libraries = [external_libraries, external_libraries_i];
        catch me
            if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                display_msg(me.message, MsgType.ERROR, 'write_during_action', '');
            else
                display_msg(me.getReport(), MsgType.DEBUG, 'write_during_action', '');
            end
            display_msg(sprintf('During Action failed for state %s', ...
                state.Origin_path),...
                MsgType.ERROR, 'write_during_action', '');
        end
    end
    if isempty(body)
        return;
    end
    %create the node
    act_node_name = ...
        SF2LusUtils.getDuringActionNodeName(state);
    main_node = LustreNode();
    main_node.setName(act_node_name);
    comment = LustreComment(...
        sprintf('During action of state %s',...
        state.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = LustreVar.uniqueVars(outputs);
    inputs = LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(act_node_name) = main_node;
end

