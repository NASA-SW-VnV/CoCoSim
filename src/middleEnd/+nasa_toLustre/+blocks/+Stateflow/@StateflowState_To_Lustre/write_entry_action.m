%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ENTRY ACTION
function [main_node, external_libraries] = ...
        write_entry_action(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
    import nasa_toLustre.blocks.Stateflow.utils.*
    external_libraries = {};
    main_node = {};
    body = {};
    outputs = {};
    inputs = {};
    %set state as active
    parentName = fileparts(state.Path);
    isChart = false;
    if isempty(parentName)
        %main chart
        isChart = true;
    end
    if ~isChart
        if ~isKey(SF_STATES_PATH_MAP, parentName)
            ME = MException('COCOSIM:STATEFLOW', ...
                'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
            throw(ME);
        end
        state_parent = SF_STATES_PATH_MAP(parentName);
        idParentName = StateflowState_To_Lustre.getStateIDName(state_parent);
        [stateEnumType, childName] = ...
            StateflowState_To_Lustre.addStateEnum(state_parent, state);
        body{1} = LustreComment('set state as active');
        body{2} = LustreEq(VarIdExpr(idParentName), childName);
        outputs{1} = LustreVar(idParentName, stateEnumType);

        %isInner variable that tells if the transition that cause this
        %exit action is an inner Transition
        isInner = VarIdExpr(SF_To_LustreNode.isInnerStr());
        inputs{end + 1} = LustreVar(isInner, 'bool');
        %actions code
        actions = SFIRPPUtils.split_actions(state.Actions.Entry);
        nb_actions = numel(actions);
        for i=1:nb_actions
            try
                [lus_action, outputs_i, inputs_i, external_libraries_i] = ...
                    getPseudoLusAction(actions{i}, data_map, false, state.Path);
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i, outputs_i];
                external_libraries = [external_libraries, external_libraries_i];
                new_assignements = SF2LusUtils.addInnerCond(lus_action, isInner, actions{i}, state);
                body = MatlabUtils.concat(body, new_assignements);
            catch me
                if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                    display_msg(me.message, MsgType.ERROR, 'write_entry_action', '');
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'write_entry_action', '');
                end
                display_msg(sprintf('Entry Action failed for state %s', ...
                    state.Origin_path),...
                    MsgType.ERROR, 'write_entry_action', '');
            end
        end
    end
    %write children states entry action
    [actions, outputs_i, inputs_i] = ...
        StateflowState_To_Lustre.write_children_actions(state, 'Entry');
    body = [body, actions];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    %create the node
    act_node_name = ...
        StateflowState_To_Lustre.getEntryActionNodeName(state);
    main_node = LustreNode();
    main_node.setName(act_node_name);
    comment = LustreComment(...
        sprintf('Entry action of state %s',...
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
