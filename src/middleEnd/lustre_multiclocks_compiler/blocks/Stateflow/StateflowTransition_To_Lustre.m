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
                get_TransitionNode(T, src, isDefaultTrans, parent_path)
            global SF_STATES_NODESAST_MAP;
            external_libraries = {};
            
            % create body
            [body, outputs, inputs] = ...
                StateflowTransition_To_Lustre.transition_code(T, isDefaultTrans, parent_path);
            
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
        
        
        
        %% Transition code
        function [body, outputs, inputs, external_libraries, antiCondition] = ...
                transition_code(transitions, isDefaultTrans, parentPath, ...
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
            external_libraries = {};
            if ~iscell(transitions)
                transitions2{1} = transitions;
                transitions = transitions2;
            end
            lastDestination = transitions{end}.Destination;
            if (strcmp(lastDestination.Type,'CONNECTIVE') ...
                    || strcmp(lastDestination.Type,'HISTORY'))
                if ~isKey(SF_JUNCTIONS_PATH_MAP, lastDestination.Name)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found Junction "%s" in SF_JUNCTIONS_PATH_MAP', lastDestination.Name);
                    throw(ME);
                end
                transitions2 = SF_JUNCTIONS_PATH_MAP(lastDestination.Name).OuterTransitions;
                n = numel(transitions2);
            else
                n = 0;
            end
            if (strcmp(lastDestination.Type,'CONNECTIVE') ...
                    || strcmp(lastDestination.Type,'HISTORY')) ...
                    && n > 0
                %keep getting the whole path to the final destination.
                for i=1:n
                    t_list = [transitions, transitions2(i)];
                    [body_i, outputs_i, inputs_i, external_libraries_i, antiCondition]= ...
                        StateflowTransition_To_Lustre.transition_code(t_list, ...
                        isDefaultTrans, parentPath, ...
                        first_cond_should_be_printed, antiCondition);
                    body = [ body , body_i ];
                    outputs = [ outputs , outputs_i ] ;
                    inputs = [ inputs , inputs_i ] ;
                    external_libraries = [external_libraries , external_libraries_i];
                end
            else
                full_path_trace = StateflowTransition_To_Lustre.get_full_path_trace(transitions, isDefaultTrans);
                body{end+1} = LustreComment(sprintf('transition trace :\n\t%s', full_path_trace), true);
                [body_i, outputs_i, inputs_i, external_libraries_i, antiCondition]= ...
                    StateflowTransition_To_Lustre.full_transition_code(transitions, ...
                    isDefaultTrans, parentPath, ...
                    first_cond_should_be_printed, antiCondition);
                body = [ body , body_i ];
                outputs = [ outputs , outputs_i ] ;
                inputs = [ inputs , inputs_i ] ;
                external_libraries = [external_libraries , external_libraries_i];
            end
            
        end
        %% Full path of transitions code
        function [body, outputs, inputs, external_libraries, antiCondition] = ...
                full_transition_code(transitions, isDefaultTrans, parentPath, ...
                first_cond_should_be_printed, antiCondition)
            
            % Execute all conditions actions along the transition full path.
            [body, outputs, inputs, external_libraries, trans_cond] = ...
                StateflowTransition_To_Lustre.full_tran_cond_actions(...
                transitions, first_cond_should_be_printed, antiCondition);

            % If the path has no state as final destination,
            %only conditions Actions are executed
            if strcmp(transitions{end}.Destination.Type,'Junction')
                return;
            end
            
            % Exit action, Transition actions and Entry action should be executed.
            if ~isDefaultTrans
                [body_i, outputs_i, inputs_i, external_libraries_i] = ...
                    StateflowTransition_To_Lustre.full_tran_exit_actions(...
                    transitions, parentPath, trans_cond);
                body = [body, body_i];
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
        end
        
        function [body, outputs, inputs, external_libraries, trans_cond] = ...
                full_tran_cond_actions(transitions, ...
                first_cond_should_be_printed, antiCondition)
            global SF_STATES_NODESAST_MAP;
            body = {};
            outputs = {};
            inputs = {};
            external_libraries = {};
            nbTrans = numel(transitions);
            trans_cond = {};
            if ~isempty(antiCondition)
                %the negation of the condition of the previous path to an actual
                %destination. In case a state Destination reached, no more transitions
                %should be executed.
                trans_cond = UnaryExpr(UnaryExpr.NOT, antiCondition);
            end
            
            % Execute all conditions actions along the transition full path.
            for i=1:nbTrans
                t = transitions{i};
                
                [condition, outputs_i, inputs_i, external_libraries_i] = ...
                    SF_To_LustreNode.getPseudoLusAction(t.Condition, true);
                print_condition = (i>1 || first_cond_should_be_printed);
                
                if print_condition && ~isempty(condition)
                    outputs = [ outputs , outputs_i ] ;
                    inputs = [ inputs , inputs_i ] ;
                    external_libraries = [external_libraries, external_libraries_i];
                    if ~isempty(trans_cond)
                        trans_cond = BinaryExpr(BinaryExpr.AND, trans_cond, condition);
                    else
                        trans_cond = condition;
                    end
                end
                source = t.Source;%Path of the source
                transCondActionNodeName = ...
                    StateflowTransition_To_Lustre.getCondActionNodeName(t, ...
                    source);
                if isKey(SF_STATES_NODESAST_MAP, transCondActionNodeName)
                    %condition Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(transCondActionNodeName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall();
                    if isempty(trans_cond)
                        body{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        body{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                end
            end
        end
        
        function [body, outputs, inputs, external_libraries] = ...
                full_tran_exit_actions(transitions, parentPath, trans_cond)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            body = {};
            outputs = {};
            inputs = {};
            external_libraries = {};
            %Add Exit Actions
            first_source = SF_STATES_PATH_MAP(transitions{1}.Source);
            last_destination = transitions{end}.Destination;
            source_parent = first_source;
            if ~strcmp(source_parent.Path, parentPath)
                %Go to the same level of the destination.
                while ~StateflowTransition_To_Lustre.isParent(...
                        StateflowTransition_To_Lustre.getParent(source_parent),...
                        last_destination)
                    source_parent = ...
                        StateflowTransition_To_Lustre.getParent(source_parent);
                end
                if isequal(source_parent.Composition.Type,'AND')
                    %Parallel state Exit.
                    parent = ...
                        StateflowTransition_To_Lustre.getParent(source_parent);
                    siblings = SF_To_LustreNode.orderObjects(...
                        StateflowState_To_Lustre.getSubStatesObjects(parent), ...
                        'ExecutionOrder');
                    nbrsiblings = numel(siblings);
                    for i=nbrsiblings:-1:1
                        exitNodeName = ...
                            StateflowState_To_Lustre.getExitActionNodeName(siblings{i});
                        if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                            %condition Action exists.
                            actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                            [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(false));
                            if isempty(trans_cond)
                                body{end+1} = LustreEq(oututs_Ids, call);
                                outputs = [outputs, actionNodeAst.getOutputs()];
                                inputs = [inputs, actionNodeAst.getInputs()];
                            else
                                body{end+1} = LustreEq(oututs_Ids, ...
                                    IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                                outputs = [outputs, actionNodeAst.getOutputs()];
                                inputs = [inputs, actionNodeAst.getOutputs()];
                                inputs = [inputs, actionNodeAst.getInputs()];
                            end
                        end
                        
                    end
                else
                    %Not Parallel state Exit
                    exitNodeName = ...
                        StateflowState_To_Lustre.getExitActionNodeName(source_parent);
                    if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                        %condition Action exists.
                        actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                        [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(false));
                        if isempty(trans_cond)
                            body{end+1} = LustreEq(oututs_Ids, call);
                            outputs = [outputs, actionNodeAst.getOutputs()];
                            inputs = [inputs, actionNodeAst.getInputs()];
                        else
                            body{end+1} = LustreEq(oututs_Ids, ...
                                IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                            outputs = [outputs, actionNodeAst.getOutputs()];
                            inputs = [inputs, actionNodeAst.getOutputs()];
                            inputs = [inputs, actionNodeAst.getInputs()];
                        end
                    end
                end
            else
                %the case of inner transition where we don't exit the parent state but we
                %exit active child
                exitNodeName = ...
                    StateflowState_To_Lustre.getExitActionNodeName(source_parent);
                if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                    %condition Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(true));
                    if isempty(trans_cond)
                        body{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        body{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                end
            end
        end
        %% Utils functions
        function full_path_trace = get_full_path_trace(transitions, isDefaultTrans)
            transition_name = cell(numel(transitions), 1);
            for i=1:numel(transitions)
                transition = transitions{i};
                if isDefaultTrans && i==1
                    transition_name{i} = 'Default_Transition';
                else
                    transition_name{i} = ...
                        StateflowTransition_To_Lustre.getUniqueName(transition, transition.Source);
                end
            end
            full_path_trace = MatlabUtils.strjoin(transition_name,', ');
        end
        
        function is_parent = isParent(Parent,child)
            if isfield(child, 'Path')
                childPath = child.Path;
            else
                %in destination struct, Name refers to Path. IR problem
                childPath = child.Name;
            end
            if isfield(Parent, 'Path')
                ParentPath = Parent.Path;
            else
                %in destination struct, Name refers to Path. IR problem
                ParentPath = Parent.Name;
            end
            is_parent = MatlabUtils.startsWith(childPath, ParentPath);
        end
        
        function parent = getParent(child)
            global SF_STATES_PATH_MAP;
            if isfield(child, 'Path')
                childPath = child.Path;
            else
                %in destination struct, Name refers to Path. IR problem
                childPath = child.Name;
            end
            parent = SF_STATES_PATH_MAP(fileparts(childPath));
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
                sourceName = '_DefaultTransition';
            else
                sourceName = SF_To_LustreNode.getUniqueName(src);
            end
            unique_name = sprintf('%s_To_%s_ExecutionOrder%s',...
                sourceName, ...
                SF_To_LustreNode.getUniqueName(dst), id_str );
            
        end
        function node_name = getCondActionNodeName(T, src, isDefaultTrans)
            if nargin < 3
                if isempty(src)
                    isDefaultTrans = true;
                else
                    isDefaultTrans = false;
                end
            end
            transition_prefix = ...
                StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Cond_Act', transition_prefix);
        end
        function node_name = getTranActionNodeName(T, src, isDefaultTrans)
            if nargin < 3
                if isempty(src)
                    isDefaultTrans = true;
                else
                    isDefaultTrans = false;
                end
            end
            transition_prefix = ...
                StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Tran_Act', transition_prefix);
        end
        function node_name = getTransitionNodeName(T, src, isDefaultTrans)
            if nargin < 3
                if isempty(src)
                    isDefaultTrans = true;
                else
                    isDefaultTrans = false;
                end
            end
            transition_prefix = StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Node', transition_prefix);
        end
        
    end
    
end

