
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% State actions
function [action_nodes,  external_libraries] = ...
        get_state_actions(state, data_map)
    
    action_nodes = {};
    %write_entry_action
    [entry_action_node, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_entry_action(state, data_map);
    if ~isempty(entry_action_node)
        action_nodes{end+1} = entry_action_node;
    end
    %write_exit_action
    [exit_action_node, ext_lib] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_exit_action(state, data_map);
    if ~isempty(exit_action_node)
        action_nodes{end+1} = exit_action_node;
    end
    %write_during_action
    external_libraries = [external_libraries, ext_lib];
    [during_action_node, ext_lib2] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_during_action(state, data_map);
    if ~isempty(during_action_node)
        action_nodes{end+1} = during_action_node;
    end
    external_libraries = [external_libraries, ext_lib2];
end
