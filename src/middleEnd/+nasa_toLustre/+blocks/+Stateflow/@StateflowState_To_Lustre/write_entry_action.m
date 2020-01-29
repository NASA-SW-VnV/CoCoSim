%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ENTRY ACTION
function [main_node, external_libraries] = ...
        write_entry_action(state, data_map)
    
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
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
        idParentName = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDName(state_parent);
        [stateEnumType, childName] = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(state_parent, state);
        body{1} = nasa_toLustre.lustreAst.LustreComment('set state as active');
        body{2} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idParentName), childName);
        outputs{1} = nasa_toLustre.lustreAst.LustreVar(idParentName, stateEnumType);

        %isInner variable that tells if the transition that cause this
        %exit action is an inner Transition
        isInner = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.isInnerStr());
        inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(isInner, 'bool');
        %actions code
        actions = nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(state.Actions.Entry);
        nb_actions = numel(actions);
        for i=1:nb_actions
            try
                [lus_action, outputs_i, inputs_i, external_libraries_i] = ...
                    nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(actions{i}, data_map, false, state.Path);
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i, outputs_i];
                external_libraries = [external_libraries, external_libraries_i];
                new_assignements = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addInnerCond(lus_action, isInner, actions{i}, state);
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
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_children_actions(state, 'Entry');
    body = [body, actions];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    %create the node
    act_node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(state);
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(act_node_name);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Entry action of state %s',...
        state.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(act_node_name) = main_node;
end
