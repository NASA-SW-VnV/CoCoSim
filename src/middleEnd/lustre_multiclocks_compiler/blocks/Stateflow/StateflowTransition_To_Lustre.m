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
        function [action_nodes, external_libraries ] = ...
                get_Actions(T, source_state, isDefaultTrans)
            action_nodes = {};
            [ConditionAction_node, ConditionAction_external_nodes, ConditionActionext_ernal_libraries ] = ...
                StateflowTransition_To_Lustre.write_ConditionAction(T, source_state, isDefaultTrans);
            if ~isempty(ConditionAction_node)
                action_nodes{end+1} = ConditionAction_node;
            end
            action_nodes = [action_nodes, ConditionAction_external_nodes];
            external_libraries = ConditionActionext_ernal_libraries;
            [TransitionAction_node, TransitionAction_external_nodes, TransitionAction_external_libraries ] = ...
                StateflowTransition_To_Lustre.write_TransitionAction(T, source_state, isDefaultTrans);
            if ~isempty(TransitionAction_node)
                action_nodes{end+1} = TransitionAction_node;
            end
            action_nodes = [action_nodes, TransitionAction_external_nodes];
            external_libraries = [external_libraries, TransitionAction_external_libraries];
        end
        
        function [transitionNode, external_libraries] = ...
                get_TransitionNode(T, src, isDefaultTrans)
            global SF_STATES_NODESAST_MAP;
            external_libraries = {};
            
            % create body
            [body, outputs, inputs] = ...
                StateflowTransition_To_Lustre.transition_code(T, src, isDefaultTrans);
            
            % creat node
            node_name = ...
                StateflowTransition_To_Lustre.getTransitionNodeName(T, src, isDefaultTrans);
            transitionNode = LustreNode();
            transitionNode.setName(node_name);
            if isDefaultTrans
                suffix = 'Default Transition';
            else
                suffix = '';
            end
            comment = LustreComment(...
                sprintf('Transition from %s %s to %s ExecutionOrder %d Node',...
                src.Path,...
                suffix, ...
                T.Destination.Name, ...
                T.ExecutionOrder), true);
            transitionNode.setMetaInfo(comment);
            transitionNode.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            transitionNode.setOutputs(outputs);
            transitionNode.setInputs(inputs);
            SF_STATES_NODESAST_MAP(node_name) = transitionNode;
        end
        %% Condition and Transition Actions
        function  [main_node, external_nodes, external_libraries ] = ...
                write_ConditionAction(T, source_state, isDefaultTrans)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, source_state, 'ConditionAction', isDefaultTrans);
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_TransitionAction(T, source_state, isDefaultTrans)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, source_state, 'TransitionAction', isDefaultTrans);
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action(T, source_state, type, isDefaultTrans)
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            global SF_STATES_NODESAST_MAP;
            if isequal(type, 'ConditionAction')
                t_act_node_name = StateflowTransition_To_Lustre.getCondActionNodeName(T, source_state, isDefaultTrans);
                action = T.ConditionAction;
            else
                t_act_node_name = StateflowTransition_To_Lustre.getTranActionNodeName(T, source_state, isDefaultTrans);
                action = T.TransitionAction;
            end
            if isKey(SF_STATES_NODESAST_MAP, t_act_node_name)
                %already handled in StateflowState_To_Lustre
            else
                [main_node, external_nodes, external_libraries ] = ...
                    StateflowTransition_To_Lustre.write_Action_Node(action, t_act_node_name);
                if ~isempty(main_node)
                    if isDefaultTrans
                        suffix = 'Default Transition';
                    else
                        suffix = '';
                    end
                    comment = LustreComment(...
                        sprintf('Transition from %s %s to %s ExecutionOrder %d %s',...
                        source_state.Path,...
                        suffix, ...
                        T.Destination.Name, ...
                        T.ExecutionOrder, type), true);
                    main_node.setMetaInfo(comment);
                end
            end
            
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action_Node(action, t_act_node_name)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            actions = SFIRPPUtils.split_actions(action);
            if ~isempty(actions)
                body = {};
                outputs = {};
                inputs = {};
                nb_actions = numel(actions);
                for i=1:nb_actions
                    [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                        SF_To_LustreNode.getPseudoLusAction(actions{i});
                    outputs = [outputs, outputs_i];
                    inputs = [inputs, inputs_i];
                    external_libraries = [external_libraries, external_libraries_i];
                end
                main_node = LustreNode();
                main_node.setName(t_act_node_name);
                main_node.setBodyEqs(body);
                outputs = LustreVar.uniqueVars(outputs);
                inputs = LustreVar.uniqueVars(inputs);
                main_node.setOutputs(outputs);
                main_node.setInputs(inputs);
                SF_STATES_NODESAST_MAP(t_act_node_name) = main_node;
            end
        end
        
        
        %% Get unique short name
        function unique_name = getUniqueName(object, src, isDefaultTrans)
            if nargin < 3
                if isempty(src)
                    isDefaultTrans = true;
                else
                    isDefaultTrans = false;
                end
            end
            dst = object.Destination;
            id_str = sprintf('%.0f', object.ExecutionOrder);
            if isDefaultTrans
                suffix = '_DefaultTransition';
            else
                suffix = '';
            end
            unique_name = sprintf('%s%s_To_%s_ExecutionOrder%s',...
                SF_To_LustreNode.getUniqueName(src),...
                suffix, ...
                SF_To_LustreNode.getUniqueName(dst), id_str );
            
        end
        function node_name = getCondActionNodeName(T, src, isDefaultTrans)
            transition_prefix = ...
                StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Cond_Act', transition_prefix);
        end
        function node_name = getTranActionNodeName(T, src, isDefaultTrans)
            transition_prefix = ...
                StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Tran_Act', transition_prefix);
        end
        function node_name = getTransitionNodeName(T, src, isDefaultTrans)
            transition_prefix = StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Node', transition_prefix);
        end
        
        %% Transition code
        function [body, outputs, inputs, antiCondition] = transition_code(transitions, src, isDefaultTrans, ...
                first_cond_should_be_printed, antiCondition)
            % This function get first the full path from source state to
            % last destination. When having junctions, all paths are
            % explored.
            global SF_JUNCTIONS_PATH_MAP;
            %first_cond_should_be_printed : is used as true from state
            %actions nodes and as false from state node. Because in state
            %node the condition is already evaluated.
            if ~exist('first_cond_should_be_printed', 'var')
                first_cond_should_be_printed = false;
            end
            %anti condition, is the conjunction of the conditions of
            %previous paths. That shoud not be true while executing the
            %current path
            if ~exist('antiCondition', 'var')
                antiCondition = {};
            end
            body = {};
            outputs = {};
            inputs = {};
            if ~iscell(transitions)
                transitions{1} = transitions;
            end
            lastDestination = transitions{end}.Destination;
            if strcmp(lastDestination.Type,'CONNECTIVE') ...
                    || strcmp(lastDestination.Type,'HISTORY')
                %keep getting the whole path to the final destination.
                if ~isKey(SF_JUNCTIONS_PATH_MAP, lastDestination.Name)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found Junction "%s" in SF_JUNCTIONS_PATH_MAP', lastDestination.Name);
                    throw(ME);
                end
                transitions2 = SF_JUNCTIONS_PATH_MAP(lastDestination.Name).OuterTransitions;
                n = numel(transitions2);
                if n==0
                    full_path_trace = StateflowTransition_To_Lustre.get_full_path_trace(transitions);
                    body{end+1} = LustreComment(sprintf('transition trace :\n\t%s', full_path_trace), true);
                    [body_i, outputs_i, inputs_i, antiCondition]= ...
                        StateflowTransition_To_Lustre.full_transition_code(transitions, src, isDefaultTrans, ...
                        first_cond_should_be_printed, antiCondition);
                    body = [ body , body_i ];
                    outputs = [ outputs , outputs_i ] ;
                    inputs = [ inputs , inputs_i ] ;
                else
                    for i=1:n
                        t_list = [transitions, transitions2{i}];
                        [body_i, outputs_i, inputs_i, antiCondition]= ...
                            StateflowTransition_To_Lustre.transition_code(t_list, src, isDefaultTrans, ...
                            first_cond_should_be_printed, antiCondition);
                        body = [ body , body_i ];
                        outputs = [ outputs , outputs_i ] ;
                        inputs = [ inputs , inputs_i ] ;
                    end
                end
            else
                full_path_trace = StateflowTransition_To_Lustre.get_full_path_trace(transitions);
                body{end+1} = LustreComment(sprintf('transition trace :\n\t%s', full_path_trace), true);
                [body_i, outputs_i, inputs_i, antiCondition]= ...
                    StateflowTransition_To_Lustre.full_transition_code(transitions, src, isDefaultTrans, ...
                    first_cond_should_be_printed, antiCondition);
                body = [ body , body_i ];
                outputs = [ outputs , outputs_i ] ;
                inputs = [ inputs , inputs_i ] ;
            end
            
        end
        function [body, outputs, inputs, antiCondition] = full_transition_code(transitions, src, isDefaultTrans, ...
                first_cond_should_be_printed, antiCondition)
            body = {};
            outputs = {};
            inputs = {};
        end
        function full_path_trace = get_full_path_trace(transitions)
            transition_name = {};
            for i=1:numel(transitions)
                transition = transitions{i};
                transition_name{i} = ...
                    StateflowTransition_To_Lustre.getUniqueName(transition, transition.Source);
            end
            full_path_trace = MatlabUtils.strjoin(transition_name,', ');
        end
    end
    
end

