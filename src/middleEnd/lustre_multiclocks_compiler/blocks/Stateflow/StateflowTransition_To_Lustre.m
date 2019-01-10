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
                get_Actions(T, data_map, source_state, isDefaultTrans)
            action_nodes = {};
            [ConditionAction_node, ConditionAction_external_nodes, ConditionActionext_ernal_libraries ] = ...
                StateflowTransition_To_Lustre.write_ConditionAction(T, data_map, source_state, isDefaultTrans);
            if ~isempty(ConditionAction_node)
                action_nodes{end+1} = ConditionAction_node;
            end
            action_nodes = [action_nodes, ConditionAction_external_nodes];
            external_libraries = ConditionActionext_ernal_libraries;
            [TransitionAction_node, TransitionAction_external_nodes, TransitionAction_external_libraries ] = ...
                StateflowTransition_To_Lustre.write_TransitionAction(T, data_map, source_state, isDefaultTrans);
            if ~isempty(TransitionAction_node)
                action_nodes{end+1} = TransitionAction_node;
            end
            action_nodes = [action_nodes, TransitionAction_external_nodes];
            external_libraries = [external_libraries, TransitionAction_external_libraries];
        end
        
        %get_DefaultTransitionsNode
        function [transitionNode, external_libraries] = ...
                get_DefaultTransitionsNode(state, data_map)
            parentPath = state.Path;
            T = SF_To_LustreNode.orderObjects(...
                state.Composition.DefaultTransitions, 'ExecutionOrder');
            isDefaultTrans = true;
            node_name = ...
                StateflowState_To_Lustre.getStateDefaultTransNodeName(state);
            comment = LustreComment(...
                sprintf('Default transitions of state %s', state.Origin_path), true);
            [transitionNode, external_libraries] = ...
                StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment);
        end
        
        %get_InnerTransitionsNode
        function [transitionNode, external_libraries] = ...
                get_InnerTransitionsNode(state, data_map)
            transitionNode = {};
            external_libraries = {};
            parentPath = state.Path;
            stateParent = fileparts(state.Path);
            if isempty(stateParent)
                %main chart
                return;
            end
            T = SF_To_LustreNode.orderObjects(...
                state.InnerTransitions, 'ExecutionOrder');
            isDefaultTrans = false;
            node_name = ...
                StateflowState_To_Lustre.getStateInnerTransNodeName(state);
            comment = LustreComment(...
                sprintf('Inner transitions of state %s', state.Origin_path), true);
            [transitionNode, external_libraries] = ...
                StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment);
        end
        %get_OuterTransitionsNode
        function [transitionNode, external_libraries] = ...
                get_OuterTransitionsNode(state, data_map)
            transitionNode = {};
            external_libraries = {};
            parentPath = fileparts(state.Path);
            if isempty(parentPath)
                %main chart
                return;
            end
            T = SF_To_LustreNode.orderObjects(...
                state.OuterTransitions, 'ExecutionOrder');
            isDefaultTrans = false;
            node_name = ...
                StateflowState_To_Lustre.getStateOuterTransNodeName(state);
            comment = LustreComment(...
                sprintf('Outer transitions of state %s', state.Origin_path), true);
            [transitionNode, external_libraries] = ...
                StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment);
        end
        %getTransitionsNode
        function [transitionNode, external_libraries] = ...
                getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment)
            global SF_STATES_NODESAST_MAP;
            transitionNode = {};
            external_libraries = {};
            if isempty(parentPath)
                %main chart
                return;
            end
            if isempty(T)
                return;
            end
            % create body
            [body, outputs, inputs, variables, external_libraries] = ...
                StateflowTransition_To_Lustre.transitions_code(T, data_map, ...
                isDefaultTrans, parentPath, {}, {}, {}, {}, {});
            
            
            % creat node
            transitionNode = LustreNode();
            transitionNode.setName(node_name);
            transitionNode.setMetaInfo(comment);
            transitionNode.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            variables = LustreVar.uniqueVars(variables);
            transitionNode.setOutputs(outputs);
            transitionNode.setInputs(inputs);
            transitionNode.setLocalVars(variables);
            SF_STATES_NODESAST_MAP(node_name) = transitionNode;
        end
        %% Condition and Transition Actions
        function  [main_node, external_nodes, external_libraries ] = ...
                write_ConditionAction(T, data_map, source_state, isDefaultTrans)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, data_map, source_state, 'ConditionAction', isDefaultTrans);
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_TransitionAction(T, data_map, source_state, isDefaultTrans)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, data_map, source_state, 'TransitionAction', isDefaultTrans);
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action(T, data_map, source_state, type, isDefaultTrans)
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
                    StateflowTransition_To_Lustre.write_Action_Node(action, data_map, t_act_node_name);
                if ~isempty(main_node)
                    if isDefaultTrans
                        suffix = 'Default Transition';
                    else
                        suffix = '';
                    end
                    comment = LustreComment(...
                        sprintf('Transition from %s %s to %s ExecutionOrder %d %s',...
                        source_state.Origin_path,...
                        suffix, ...
                        T.Destination.Origin_path, ...
                        T.ExecutionOrder, type), true);
                    main_node.setMetaInfo(comment);
                end
            end
            
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action_Node(action, data_map, t_act_node_name)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            actions = SFIRPPUtils.split_actions(action);
            if isempty(actions)
                return;
            end
            body = {};
            outputs = {};
            inputs = {};
            nb_actions = numel(actions);
            for i=1:nb_actions
                [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                    getPseudoLusAction(actions{i}, data_map);
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
            main_node = LustreNode();
            main_node.setName(t_act_node_name);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(t_act_node_name) = main_node;
            
        end
        
        
        
        %% Transition code
        function [body, outputs, inputs, variables, external_libraries, ...
                validDestination_cond, Termination_cond] = ...
                transitions_code(transitions, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
            body = {};
            outputs = {};
            inputs = {};
            external_libraries = {};
            n = numel(transitions);
            for i=1:n
                t_list = [fullPathT, transitions(i)];
                [body_i, outputs_i, inputs_i, variables, external_libraries_i, ...
                    validDestination_cond, Termination_cond] = ...
                    StateflowTransition_To_Lustre.evaluate_Transition(...
                    transitions{i}, data_map, isDefaultTrans, parentPath, ...
                    validDestination_cond, Termination_cond, ...
                    cond_prefix, t_list, variables);
                body = [ body , body_i ];
                outputs = [ outputs , outputs_i ] ;
                inputs = [ inputs , inputs_i ] ;
                external_libraries = [external_libraries , external_libraries_i];
            end
        end
        function [body, outputs, inputs, variables, external_libraries, validDestination_cond, Termination_cond] = ...
                evaluate_Transition(t, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
            global SF_STATES_NODESAST_MAP SF_JUNCTIONS_PATH_MAP;
            body = {};
            outputs = {};
            inputs = {};
            external_libraries = {};
            % Transition is marked for evaluation.
            % Does the transition have a condition?
            [trans_cond, outputs_i, inputs_i, ~] = ...
                getPseudoLusAction(t.Condition, data_map, true);
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            [event, outputs_i, inputs_i, ~] = ...
                getPseudoLusAction(t.Event,data_map, true);
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];  
            if ~isempty(trans_cond) && ~isempty(event)
                trans_cond = BinaryExpr(BinaryExpr.AND, trans_cond, event);
            elseif ~isempty(event)
                trans_cond = event;
            end
            % add cond_prefix
            if ~isempty(cond_prefix)
                if ~isempty(trans_cond)
                    trans_cond = BinaryExpr(BinaryExpr.AND, cond_prefix, trans_cond);
                else
                    trans_cond = cond_prefix;
                end
            end
            % add condition variable so the condition action can not change
            % the truth value of the condition.
            if ~isempty(trans_cond)
                condName = StateflowTransition_To_Lustre.getCondActionName(t);
                body{end+1} = LustreEq(VarIdExpr(condName), trans_cond);
                trans_cond = VarIdExpr(condName);
                variables{end+1} = LustreVar(condName, 'bool');
            end
            
            % add no valid transition path was found
            if ~isempty(Termination_cond)
                if ~isempty(trans_cond)
                    trans_cond_with_termination = BinaryExpr(BinaryExpr.AND, ...
                        UnaryExpr(UnaryExpr.NOT, Termination_cond), trans_cond);
                else
                    trans_cond_with_termination = UnaryExpr(UnaryExpr.NOT, Termination_cond);
                end
            else
                trans_cond_with_termination = trans_cond;
            end
            
           
            
            %execute condition action
            
            transCondActionNodeName = ...
                StateflowTransition_To_Lustre.getCondActionNodeName(t);
            if isKey(SF_STATES_NODESAST_MAP, transCondActionNodeName)
                %condition Action exists.
                actionNodeAst = SF_STATES_NODESAST_MAP(transCondActionNodeName);
                [call, oututs_Ids] = actionNodeAst.nodeCall();
                if isempty(trans_cond_with_termination)
                    body{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                else
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(trans_cond_with_termination, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                end
            end
            
            
            %Is the destination a state or a junction?
            destination = t.Destination;
            isHJ = false;
            if strcmp(destination.Type,'Junction') 
                %the destination is a junction
                if isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
                    hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
                    if isequal(hobject.Type, 'HISTORY')
                        isHJ = true;
                    else
                        %Does the junction have any outgoing transitions?
                        transitions2 = SF_To_LustreNode.orderObjects(...
                            SF_JUNCTIONS_PATH_MAP(destination.Name).OuterTransitions, ...
                            'ExecutionOrder');
                        if isempty(transitions2)
                            %the junction has no outgoing transitions
                            %update termination condition
                            condName = StateflowTransition_To_Lustre.getTerminationCondName();
                            [Termination_cond, body, outputs, variables] = ...
                                StateflowTransition_To_Lustre.updateTerminationCond(...
                                Termination_cond, condName, trans_cond, body, outputs, variables, true);
                        else
                            %the junction has outgoing transitions
                            %Repeat the algorithm
                            [body_i, outputs_i, inputs_i, variables, ...
                                external_libraries_i, ...
                                validDestination_cond, Termination_cond] = ...
                                StateflowTransition_To_Lustre.transitions_code(...
                                transitions2, data_map, isDefaultTrans, ...
                                parentPath, ...
                                validDestination_cond, Termination_cond, ...
                                trans_cond, fullPathT, variables);
                            body = [body, body_i];
                            outputs = [outputs, outputs_i];
                            inputs = [inputs, inputs_i];
                            external_libraries = [external_libraries, external_libraries_i];
                        end
                        return;
                    end
                else
                    display_msg(...
                        sprintf('%s not found in SF_JUNCTIONS_PATH_MAP',...
                        destination.Name), ...
                        MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
                    return;
                end
            end
            %the destination is a state or History Junction
            % Exit action should be executed.
            if ~isDefaultTrans
                [body_i, outputs_i, inputs_i] = ...
                    StateflowTransition_To_Lustre.full_tran_exit_actions(...
                    fullPathT, parentPath, trans_cond_with_termination);
                body = [body, body_i];
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
            end
            % Transition actions
            [body_i, outputs_i, inputs_i] = ...
                StateflowTransition_To_Lustre.full_tran_trans_actions(...
                fullPathT, trans_cond_with_termination);
            body = [body, body_i];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            
            % Entry actions
            [body_i, outputs_i, inputs_i] = ...
                StateflowTransition_To_Lustre.full_tran_entry_actions(...
                fullPathT, parentPath, trans_cond_with_termination, isHJ);
            body = [body, body_i];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            
            %update termination condition
            condName = StateflowTransition_To_Lustre.getTerminationCondName();
            [Termination_cond, body, outputs, variables] = ...
                StateflowTransition_To_Lustre.updateTerminationCond(...
                Termination_cond, condName, trans_cond, body, outputs, variables, true);
            %validDestination_cond only updated if the final destination is a state
            
            if ~isDefaultTrans
                condName = StateflowTransition_To_Lustre.getValidPathCondName();
                [validDestination_cond, body, outputs, variables] = ...
                    StateflowTransition_To_Lustre.updateTerminationCond(...
                    validDestination_cond, condName, trans_cond, body, outputs, variables, false);
            end
        end
        
        function [Termination_cond, body, outputs, variables] = ...
                updateTerminationCond(Termination_cond, condName, trans_cond, ...
                body, outputs, variables, addToVariables)
            
            if addToVariables
                if VarIdExpr.ismemberVar(condName, variables)
                    i = 1;
                    new_condName = strcat(condName, num2str(i));
                    while(VarIdExpr.ismemberVar(new_condName, variables))
                        i = i + 1;
                        new_condName = strcat(condName, num2str(i));
                    end
                    condName = new_condName;
                end
            end
            if isempty(Termination_cond)
                if isempty(trans_cond)
                    body{end+1} = ...
                        LustreEq(VarIdExpr(condName), BooleanExpr('true'));
                else
                    body{end+1} = ...
                        LustreEq(VarIdExpr(condName), trans_cond);
                end
            else
                if isempty(trans_cond)
                    body{end+1} = ...
                        LustreEq(VarIdExpr(condName), BooleanExpr('true'));
                else
                    body{end+1} = ...
                        LustreEq(VarIdExpr(condName), ...
                        BinaryExpr(BinaryExpr.OR, Termination_cond, trans_cond));
                end
            end
            Termination_cond = VarIdExpr(condName);
            if addToVariables
                variables{end+1} = LustreVar(condName, 'bool');
            else
                outputs{end+1} = LustreVar(condName, 'bool');
            end
        end
        
        %transition actions
        function [body, outputs, inputs] = ...
                full_tran_trans_actions(transitions, trans_cond)
            global SF_STATES_NODESAST_MAP;
            body = {};
            outputs = {};
            inputs = {};
            nbTrans = numel(transitions);
            
            % Execute all transition actions along the transition full path.
            for i=1:nbTrans
                t = transitions{i};
                source = t.Source;%Path of the source
                transTransActionNodeName = ...
                    StateflowTransition_To_Lustre.getTranActionNodeName(t, ...
                    source);
                if isKey(SF_STATES_NODESAST_MAP, transTransActionNodeName)
                    %transition Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(transTransActionNodeName);
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
        %exit actions
        function [body, outputs, inputs] = ...
                full_tran_exit_actions(transitions, parentPath, trans_cond)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            body = {};
            outputs = {};
            inputs = {};
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
            %remove isInner input from the node inputs
            inputs_name = cellfun(@(x) x.getId(), ...
                inputs, 'UniformOutput', false);
            inputs = inputs(~strcmp(inputs_name, ...
                StateflowState_To_Lustre.isInnerStr()));
        end

        % Entry actions
        function [body, outputs, inputs, antiCondition] = ...
                full_tran_entry_actions(transitions, parentPath, trans_cond, isHJ)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            body = {};
            outputs = {};
            inputs = {};
            antiCondition = trans_cond;
            last_destination = transitions{end}.Destination;
            if isHJ
                dest_parent = StateflowTransition_To_Lustre.getParent(...
                    last_destination);
            else
                dest_parent = SF_STATES_PATH_MAP(last_destination.Name);
            end
            first_source = transitions{1}.Source;
            if ~strcmp(dest_parent.Path, parentPath)
                %Go to the same level of the destination.
                while ~StateflowTransition_To_Lustre.isParent(...
                        StateflowTransition_To_Lustre.getParent(dest_parent),...
                        first_source)
                    child = dest_parent;
                    dest_parent = ...
                        StateflowTransition_To_Lustre.getParent(dest_parent);
                    
                    % set the child as active, so when the parent execute
                    % entry action, it will enter the right child.
                    if isHJ
                        continue;
                    end
                    idParentName = StateflowState_To_Lustre.getStateIDName(...
                        dest_parent);
                    [idParentEnumType, idParentStateEnum] = ...
                        StateflowState_To_Lustre.addStateEnum(dest_parent, child);
                    body{end + 1} = LustreComment(...
                        sprintf('set state %s as active', child.Name));
                    if isempty(trans_cond)
                        body{end + 1} = LustreEq(VarIdExpr(idParentName), ...
                            VarIdExpr(idParentStateEnum));
                        outputs{end + 1} = LustreVar(idParentName, idParentEnumType);
                    else
                        body{end+1} = LustreEq(VarIdExpr(idParentName), ...
                            IteExpr(trans_cond, VarIdExpr(idParentStateEnum), ...
                            VarIdExpr(idParentName)));
                        outputs{end + 1} = LustreVar(idParentName, idParentEnumType);
                        inputs{end+1} = LustreVar(idParentName, idParentEnumType);
                    end
                    
                end
                if isequal(dest_parent.Composition.Type,'AND')
                    %Parallel state Enter.
                    parent = ...
                        StateflowTransition_To_Lustre.getParent(dest_parent);
                    siblings = SF_To_LustreNode.orderObjects(...
                        StateflowState_To_Lustre.getSubStatesObjects(parent), ...
                        'ExecutionOrder');
                    nbrsiblings = numel(siblings);
                    for i=1:nbrsiblings
                        %if nbrsiblings{i}.Id == dest_parent.Id
                            %our parallel state we are entering
                        %end
                        entryNodeName = ...
                            StateflowState_To_Lustre.getEntryActionNodeName(siblings{i});
                        if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
                            %entry Action exists.
                            actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
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
                    %Not Parallel state Entry
                    entryNodeName = ...
                        StateflowState_To_Lustre.getEntryActionNodeName(dest_parent);
                    if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
                        actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
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
                % this is a case of inner transition where the destination is
                %the parent state. We should not execute entry state of the parent
                
                if ~isHJ
                    idState = StateflowState_To_Lustre.getStateIDName(...
                        dest_parent);
                    [idStateEnumType, idStateInactiveEnum] = ...
                        StateflowState_To_Lustre.addStateEnum(dest_parent, [], ...
                        false, false, true);
                    body{end + 1} = LustreComment(...
                        sprintf('set state %s as inactive', dest_parent.Name));
                    if isempty(trans_cond)
                        body{end + 1} = LustreEq(VarIdExpr(idState), ...
                            VarIdExpr(idStateInactiveEnum));
                        outputs{end + 1} = LustreVar(idState, idStateEnumType);
                    else
                        body{end+1} = LustreEq(VarIdExpr(idState), ...
                            IteExpr(trans_cond, VarIdExpr(idStateInactiveEnum), ...
                            VarIdExpr(idState)));
                        outputs{end + 1} = LustreVar(idState, idStateEnumType);
                        inputs{end+1} = LustreVar(idState, idStateEnumType);
                    end
                end
                entryNodeName = ...
                    StateflowState_To_Lustre.getEntryActionNodeName(dest_parent);
                if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
                    actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
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
            %remove isInner input from the node inputs
            inputs_name = cellfun(@(x) x.getId(), ...
                inputs, 'UniformOutput', false);
            inputs = inputs(~strcmp(inputs_name, ...
                StateflowState_To_Lustre.isInnerStr()));
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
            if isempty(child)
                is_parent = true;
                return;
            end
            if ischar(child)
                childPath = child;
            elseif isfield(child, 'Path')
                childPath = child.Path;
            else
                %in destination struct, Name refers to Path. IR problem
                childPath = child.Name;
            end
            if ischar(Parent)
                ParentPath = Parent;
            elseif isfield(Parent, 'Path')
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
            if nargin < 2
                src = T.Source;
            end
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
        function node_name = getCondActionName(T)
            src = T.Source;
            if isempty(src)
                isDefaultTrans = true;
            else
                isDefaultTrans = false;
            end
            transition_prefix = ...
                StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
            node_name = sprintf('%s_Cond', transition_prefix);
        end
        function node_name = getCondActionNodeName(T, src, isDefaultTrans)
            if nargin < 2
                src = T.Source;
            end
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
            if nargin < 2
                src = T.Source;
            end
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
        function varName = getTerminationCondName()
            varName = '_TERMINATION_COND';
        end
        function varName = getValidPathCondName()
            varName = '_FOUND_VALID_PATH';
        end
    end
    
end

