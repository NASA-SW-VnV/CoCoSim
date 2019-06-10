
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function  [main_node, external_nodes, external_libraries ] = ...
        write_Action(T, data_map, source_state, type, isDefaultTrans)
    
    main_node = {};
    external_nodes = {};
    external_libraries = {};
    if strcmp(type, 'ConditionAction')
        t_act_node_name = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getCondActionNodeName(T, source_state, isDefaultTrans);
        action = T.ConditionAction;
    else
        t_act_node_name = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTranActionNodeName(T, source_state, isDefaultTrans);
        action = T.TransitionAction;
    end
    if isDefaultTrans
        suffix = 'Default Transition';
    else
        suffix = '';
    end
    transitionPath = sprintf('Transition from %s %s to %s ExecutionOrder %d %s',...
        source_state.Origin_path,...
        suffix, ...
        T.Destination.Origin_path, ...
        T.ExecutionOrder, type);
    [main_node, external_nodes, external_libraries ] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.write_Action_Node(action, data_map, t_act_node_name, transitionPath);
    if ~isempty(main_node)
        comment = nasa_toLustre.lustreAst.LustreComment(transitionPath, true);
        main_node.setMetaInfo(comment);
    end


end

