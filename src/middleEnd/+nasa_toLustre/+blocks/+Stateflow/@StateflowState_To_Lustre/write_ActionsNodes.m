
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% State Actions and DefaultTransitions Nodes
function  [external_nodes, external_libraries ] = ...
        write_ActionsNodes(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    external_nodes = {};
    external_libraries = {};
    % Create transitions actions as external nodes that will be called by the states nodes.
    function addNodes(t, isDefaultTrans)
        % Transition actions
        [transition_nodes_j, external_libraries_j ] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.get_Actions(t, data_map, state, ...
            isDefaultTrans);
        external_nodes = [external_nodes, transition_nodes_j];
        external_libraries = [external_libraries, external_libraries_j];
    end

    % Default Transitions
    T = state.Composition.DefaultTransitions;
    for i=1:numel(T)
        addNodes(T{i}, true)
    end
    [node,  external_libraries_i] = ...
        StateflowTransition_To_Lustre.get_DefaultTransitionsNode(state, data_map);
    if ~isempty(node)
        external_nodes{end+1} = node;
    end
    external_libraries = [external_libraries, external_libraries_i];

    % Create State actions as external nodes that will be called by the states nodes.
    [action_nodes,  external_libraries_i] = ...
        SF2LusUtils.get_state_actions(state, data_map);
    external_nodes = [external_nodes, action_nodes];
    external_libraries = [external_libraries, external_libraries_i];


    T = state.InnerTransitions;
    for i=1:numel(T)
        addNodes(T{i}, false)
    end
    T = state.OuterTransitions;
    for i=1:numel(T)
        addNodes(T{i}, false)
    end

end
