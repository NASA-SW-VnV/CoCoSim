
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% State actions
function [action_nodes,  external_libraries] = ...
        get_state_actions(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    action_nodes = {};
    %write_entry_action
    [entry_action_node, external_libraries] = ...
        StateflowState_To_Lustre.write_entry_action(state, data_map);
    if ~isempty(entry_action_node)
        action_nodes{end+1} = entry_action_node;
    end
    %write_exit_action
    [exit_action_node, ext_lib] = ...
        StateflowState_To_Lustre.write_exit_action(state, data_map);
    if ~isempty(exit_action_node)
        action_nodes{end+1} = exit_action_node;
    end
    %write_during_action
    external_libraries = [external_libraries, ext_lib];
    [during_action_node, ext_lib2] = ...
        StateflowState_To_Lustre.write_during_action(state, data_map);
    if ~isempty(during_action_node)
        action_nodes{end+1} = during_action_node;
    end
    external_libraries = [external_libraries, ext_lib2];
end
