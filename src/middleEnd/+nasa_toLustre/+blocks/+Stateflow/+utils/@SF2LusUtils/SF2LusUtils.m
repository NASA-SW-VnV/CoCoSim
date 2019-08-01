classdef SF2LusUtils
    %SF2LUSUTILS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
    end
    
    methods(Static)
        [outputs, inputs] = getInOutputsFromAction(lus_action, isCondition, data_map, expreession, isMatlab)
        
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
        
        %%
        % Get unique short name
        unique_name = getUniqueName(object, id)
        
        % special Var Names
        v = virtualVarStr()

        v = isInnerStr()

        % Order states, transitions ...
        ordered = orderObjects(objects, fieldName)

        % change events to data
        data = eventsToData(event_s) 

        vars = getDataVars(d_list)

        names = getDataName(d)
        SF_DATA_MAP = addArrayData(SF_DATA_MAP, d_list)
    end
end

