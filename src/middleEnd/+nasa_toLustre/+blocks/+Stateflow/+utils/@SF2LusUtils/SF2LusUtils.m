classdef SF2LusUtils
    %SF2LUSUTILS
    properties
    end
    
    methods(Static)
        [outputs, inputs] = getInOutputsFromAction(lus_action, isCondition, data_map, expreession)
        
        % this function for Entry, Exit State Actions
        new_assignements = addInnerCond(lus_eqts, isInnerLusVar, orig_exp, state)
            
        %% StateflowState_To_Lustre
        % Actions node name
        name = getChartEventsNodeName(state, id)
        
        name = getStateNodeName(state, id)
        
        name = getStateDefaultTransNodeName(state)
        
        name = getStateInnerTransNodeName(state)
        
        name = getStateOuterTransNodeName(state)
        
        name = getEntryActionNodeName(state, id)
        
        name = getExitActionNodeName(state, id)
        
        name = getDuringActionNodeName(state, id)
        
        % State ID functions
        suf = getStateIDSuffix()
        
        idName = getStateIDName(state)
        
        suf = getStateEnumSuffix()
        
        idName = getStateEnumType(state)
        
        [stateEnumType, childAst] = ...
            addStateEnum(state, child, isInner, isJunction, inactive)
        
        % Substates objects
        subStates = getSubStatesObjects(state)
        
        call = changeEvents(call, EventsNames, E)
        params = changeVar(params, oldName, newName)
        
        % State actions
        [action_nodes,  external_libraries] = ...
            get_state_actions(state, data_map)
    end
end

