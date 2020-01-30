%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef SF2LusUtils
    %SF2LUSUTILS

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

