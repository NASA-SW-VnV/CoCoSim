classdef StateflowTransition_To_Lustre
    %StateflowTransition_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% Main functions
        [action_nodes, external_libraries ] = ...
                get_Actions(T, data_map, source_state, isDefaultTrans)
        
        %get_DefaultTransitionsNode
        [transitionNode, external_libraries] = ...
                get_DefaultTransitionsNode(state, data_map)
        
        %get_InnerTransitionsNode
        [transitionNode, external_libraries] = ...
                get_InnerTransitionsNode(state, data_map)

        %get_OuterTransitionsNode
        [transitionNode, external_libraries] = ...
                get_OuterTransitionsNode(state, data_map)

        %getTransitionsNode
        [transitionNode, external_libraries] = ...
                getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment)

        %% Condition and Transition Actions
         [main_node, external_nodes, external_libraries ] = ...
                write_ConditionAction(T, data_map, source_state, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_TransitionAction(T, data_map, source_state, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_Action(T, data_map, source_state, type, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_Action_Node(action, data_map, t_act_node_name, transitionPath)

        %% Transition code
        [body, outputs, inputs, variables, external_libraries, ...
                validDestination_cond, Termination_cond] = ...
                transitions_code(transitions, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)

        [body, outputs, inputs, variables, external_libraries, validDestination_cond, Termination_cond] = ...
                evaluate_Transition(t, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
        
        [Termination_cond, body, outputs, variables] = ...
                updateTerminationCond(Termination_cond, condName, trans_cond, ...
                body, outputs, variables, addToVariables)
        
        %transition actions
        [body, outputs, inputs] = ...
                full_tran_trans_actions(transitions, trans_cond)

        %exit actions
        [body, outputs, inputs] = ...
                full_tran_exit_actions(transitions, parentPath, trans_cond)

        % Entry actions
        [body, outputs, inputs, antiCondition] = ...
                full_tran_entry_actions(transitions, parentPath, trans_cond, isHJ)

        %% Utils functions
        full_path_trace = get_full_path_trace(transitions, isDefaultTrans)
        
        is_parent = isParent(Parent,child)
        
        parent = getParent(child)

        %% Get unique short name
        unique_name = getUniqueName(object, src, isDefaultTrans)

        node_name = getCondActionName(T)

        node_name = getCondActionNodeName(T, src, isDefaultTrans)

        node_name = getTranActionNodeName(T, src, isDefaultTrans)

        varName = getTerminationCondName()
 
        varName = getValidPathCondName()

    end
    
end

