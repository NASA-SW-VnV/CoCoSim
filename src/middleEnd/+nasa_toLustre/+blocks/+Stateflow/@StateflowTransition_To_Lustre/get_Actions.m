
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Main functions
function [action_nodes, external_libraries ] = ...
        get_Actions(T, data_map, source_state, isDefaultTrans)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    action_nodes = {};
    [ConditionAction_node, ConditionAction_external_nodes, ConditionActionext_ernal_libraries ] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.write_ConditionAction(T, data_map, source_state, isDefaultTrans);
    if ~isempty(ConditionAction_node)
        action_nodes{end+1} = ConditionAction_node;
    end
    action_nodes = [action_nodes, ConditionAction_external_nodes];
    external_libraries = ConditionActionext_ernal_libraries;
    [TransitionAction_node, TransitionAction_external_nodes, TransitionAction_external_libraries ] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.write_TransitionAction(T, data_map, source_state, isDefaultTrans);
    if ~isempty(TransitionAction_node)
        action_nodes{end+1} = TransitionAction_node;
    end
    action_nodes = [action_nodes, TransitionAction_external_nodes];
    external_libraries = [external_libraries, TransitionAction_external_libraries];
end

