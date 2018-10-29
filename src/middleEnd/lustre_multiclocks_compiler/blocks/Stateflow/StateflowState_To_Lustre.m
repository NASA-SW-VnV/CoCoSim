classdef StateflowState_To_Lustre
    %StateflowState_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        %% State Actions and DefaultTransitions Nodes
        function  [external_nodes, external_libraries ] = ...
                write_ActionsNodes(state)
            external_nodes = {};
            external_libraries = {};
            
            % Default Transitions
            T = state.Composition.DefaultTransitions;
            for i=1:numel(T)
                addNodes(T{i}, true)
            end
            [node,  external_libraries_i] = ...
                StateflowTransition_To_Lustre.get_DefaultTransitionsNode(state);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            external_libraries = [external_libraries, external_libraries_i];
            
            % Create State actions as external nodes that will be called by the states nodes.
            [action_nodes,  external_libraries_i] = ...
                StateflowState_To_Lustre.get_state_actions(state);
            external_nodes = [external_nodes, action_nodes];
            external_libraries = [external_libraries, external_libraries_i];
            
            % Create transitions actions as external nodes that will be called by the states nodes.
            function addNodes(t, isDefaultTrans)
                % Transition actions
                [transition_nodes_j, external_libraries_j ] = ...
                    StateflowTransition_To_Lustre.get_Actions(t, state, ...
                    isDefaultTrans);
                external_nodes = [external_nodes, transition_nodes_j];
                external_libraries = [external_libraries, external_libraries_j];
            end
            T = state.InnerTransitions;
            for i=1:numel(T)
                addNodes(T{i}, false)
            end
            T = state.OuterTransitions;
            for i=1:numel(T)
                addNodes(T{i}, false)
            end
            
        end
        
        %% InnerTransitions and  OuterTransitions Nodes
        function  [external_nodes, external_libraries ] = ...
                write_TransitionsNodes(state)
            external_nodes = {};
            [node, external_libraries] = ...
                StateflowTransition_To_Lustre.get_InnerTransitionsNode(state);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            
            [node,  external_libraries_i] = ...
                StateflowTransition_To_Lustre.get_OuterTransitionsNode(state);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            external_libraries = [external_libraries, external_libraries_i];
        end
        
        %% State Node
        function main_node  = write_StateNode(state)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            
            [outputs, inputs, body] = ...
                StateflowState_To_Lustre.write_state_body(state);
            if isempty(body)
                %no code is required
                return;
            end
            %create the node
            node_name = ...
                StateflowState_To_Lustre.getStateNodeName(state);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(...
                sprintf('Main node of state %s',...
                state.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            else
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        
        %% Chart Node
        function [main_node, external_nodes]  = write_ChartNode(parent, blk, chart, dataAndEvents, events)
            global SF_STATES_NODESAST_MAP;
            external_nodes = {};
            Scopes = cellfun(@(x) x.Scope, ...
                events, 'UniformOutput', false);
            inputEvents = SF_To_LustreNode.orderObjects(...
                events(strcmp(Scopes, 'Input')), 'Port');
            if ~isempty(inputEvents)
                %create a node that do the multi call for each event
                eventNode  = ...
                    StateflowState_To_Lustre.write_ChartNodeWithEvents(...
                    chart, inputEvents);
                external_nodes{1} = eventNode;
            end
            [outputs, inputs, variable, body] = ...
                StateflowState_To_Lustre.write_chart_body(parent, blk, chart, dataAndEvents, inputEvents);
           
            %create the node
            node_name = ...
                SLX2LusUtils.node_name_format(blk);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(sprintf('Chart Node: %s', chart.Path),...
                true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);            
            main_node.setOutputs(outputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            end
            main_node.setInputs(inputs);
            
            main_node.setLocalVars(variable);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        
        function main_node  = write_ChartNodeWithEvents(chart, inputEvents)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            
            [outputs, inputs, body] = ...
                StateflowState_To_Lustre.write_ChartNodeWithEvents_body(chart, inputEvents);
            if isempty(body)
                %no code is required
                return;
            end
            %create the node
            node_name = ...
                StateflowState_To_Lustre.getChartEventsNodeName(chart);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(...
                sprintf('Executing Events of state %s',...
                chart.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            else
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% State actions
        function [action_nodes,  external_libraries] = ...
                get_state_actions(state)
            action_nodes = {};
            %write_entry_action
            [entry_action_node, external_libraries] = ...
                StateflowState_To_Lustre.write_entry_action(state);
            if ~isempty(entry_action_node)
                action_nodes{end+1} = entry_action_node;
            end
            %write_exit_action
            [exit_action_node, ext_lib] = ...
                StateflowState_To_Lustre.write_exit_action(state);
            if ~isempty(exit_action_node)
                action_nodes{end+1} = exit_action_node;
            end
            %write_during_action
            external_libraries = [external_libraries, ext_lib];
            [during_action_node, ext_lib2] = ...
                StateflowState_To_Lustre.write_during_action(state);
            if ~isempty(during_action_node)
                action_nodes{end+1} = during_action_node;
            end
            external_libraries = [external_libraries, ext_lib2];
        end
        %% ENTRY ACTION
        function [main_node, external_libraries] = ...
                write_entry_action(state)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            %set state as active
            parentName = fileparts(state.Path);
            isChart = false;
            if isempty(parentName)
                %main chart
                isChart = true;
            end
            if ~isChart
                if ~isKey(SF_STATES_PATH_MAP, parentName)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
                    throw(ME);
                end
                idParentName = StateflowState_To_Lustre.getStateIDName(...
                    SF_STATES_PATH_MAP(parentName));
                body{1} = LustreComment('set state as active');
                body{2} = LustreEq(VarIdExpr(idParentName), IntExpr(state.Id));
                outputs{1} = LustreVar(idParentName, 'int');
                
                %actions code
                actions = SFIRPPUtils.split_actions(state.Actions.Entry);
                nb_actions = numel(actions);
                for i=1:nb_actions
                    [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                        SF_To_LustreNode.getPseudoLusAction(actions{i});
                    outputs = [outputs, outputs_i];
                    inputs = [inputs, inputs_i];
                    external_libraries = [external_libraries, external_libraries_i];
                end
            end
            %write children states entry action
            [actions, outputs_i, inputs_i] = ...
                StateflowState_To_Lustre.write_children_actions(state, 'Entry');
            body = [body, actions];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getEntryActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('Entry action of state %s',...
                state.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            else
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        %% EXIT ACTION
        function [main_node, external_libraries] = ...
                write_exit_action(state)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            
            parentName = fileparts(state.Path);
            if isempty(parentName)
                %main chart
                return;
            end
            
            %write children states exit action
            [actions, outputs_i, inputs_i] = ...
                StateflowState_To_Lustre.write_children_actions(state, 'Exit');
            body = [body, actions];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            
            %actions code
            actions = SFIRPPUtils.split_actions(state.Actions.Exit);
            nb_actions = numel(actions);
            for i=1:nb_actions
                [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                    SF_To_LustreNode.getPseudoLusAction(actions{i});
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
            
            %set state as inactive
            if ~isKey(SF_STATES_PATH_MAP, parentName)
                ME = MException('COCOSIM:STATEFLOW', ...
                    'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
                throw(ME);
            end
            %isInner variable that tells if the transition that cause this
            %exit action is an inner Transition
            isInner = VarIdExpr(StateflowState_To_Lustre.isInnerStr());
            
            
            idParentName = StateflowState_To_Lustre.getStateIDName(...
                SF_STATES_PATH_MAP(parentName));
            body{end + 1} = LustreComment('set state as inactive');
            % idParentName = if (not isInner) then 0 else idParentName;
            body{end + 1} = LustreEq(VarIdExpr(idParentName), ...
                IteExpr(UnaryExpr(UnaryExpr.NOT, isInner), ...
                IntExpr(0), VarIdExpr(idParentName)));
            outputs{end + 1} = LustreVar(idParentName, 'int');
            inputs{end + 1} = LustreVar(idParentName, 'int');
            % add isInner input
            inputs{end + 1} = LustreVar(isInner, 'bool');
            % set state children as inactive
            junctions = state.Composition.SubJunctions;
            typs = cellfun(@(x) x.Type, junctions, 'UniformOutput', false);
            hjunctions = junctions(strcmp(typs, 'HISTORY'));
            if (~isempty(state.Composition.Substates) && isempty(hjunctions))
                idStateName = StateflowState_To_Lustre.getStateIDName(state);
                body{end+1} = LustreEq(VarIdExpr(idStateName), IntExpr(0));
                outputs{end+1} = LustreVar(idStateName, 'int');
            end
            
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getExitActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('Exit action of state %s',...
                state.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        function v = isInnerStr()
            v = '_isInner';
        end
        %% DURING ACTION
        function [main_node, external_libraries] = ...
                write_during_action(state)
            global SF_STATES_NODESAST_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            
            parentName = fileparts(state.Path);
            if isempty(parentName)
                %main chart
                return;
            end
            
            %actions code
            actions = SFIRPPUtils.split_actions(state.Actions.During);
            nb_actions = numel(actions);
            
            for i=1:nb_actions
                [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                    SF_To_LustreNode.getPseudoLusAction(actions{i});
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
            if isempty(body)
                return;
            end
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getDuringActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('During action of state %s',...
                state.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            else
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        
        %% write_children_actions
        function [actions, outputs, inputs] = ...
                write_children_actions(state, actionType)
            actions = {};
            outputs = {};
            inputs = {};
            global SF_STATES_NODESAST_MAP;
            childrenNames = state.Composition.Substates;
            nb_children = numel(childrenNames);
            childrenIDs = state.Composition.States;
            if isequal(state.Composition.Type, 'PARALLEL_AND')
                for i=1:nb_children
                    if isequal(actionType, 'Entry')
                        k=i;
                        action_node_name = ...
                            StateflowState_To_Lustre.getEntryActionNodeName(...
                            childrenNames{k}, childrenIDs{k});
                    else
                        k=nb_children - i + 1;
                        action_node_name = ...
                            StateflowState_To_Lustre.getExitActionNodeName(...
                            childrenNames{k}, childrenIDs{k});
                    end
                    if ~isKey(SF_STATES_NODESAST_MAP, action_node_name)
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            action_node_name);
                        throw(ME);
                    end
                    actionNodeAst = SF_STATES_NODESAST_MAP(action_node_name);
                    if isequal(actionType, 'Entry')
                        [call, oututs_Ids] = actionNodeAst.nodeCall();
                    else
                        [call, oututs_Ids] = actionNodeAst.nodeCall(...
                            true, BooleanExpr(false));
                    end
                    actions{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                end
            else
                concurrent_actions = {};
                idStateVar = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(state));
                if nb_children >= 1
                    inputs{end+1} = LustreVar(idStateVar, 'int');
                end
                default_transition = state.Composition.DefaultTransitions;
                if isequal(actionType, 'Entry')...
                        && ~isempty(default_transition)
                    % we need to get the default condition code, as the
                    % default transition decides what sub-state to enter while.
                    % entering the state. This is the case where stateId ==
                    % 0;
                    %get_initial_state_code
                    node_name = ...
                        StateflowState_To_Lustre.getStateDefaultTransNodeName(state);
                    cond = BinaryExpr(BinaryExpr.EQ, ...
                        idStateVar, IntExpr(0));
                    if isKey(SF_STATES_NODESAST_MAP, node_name)
                        actionNodeAst = SF_STATES_NODESAST_MAP(node_name);
                        [call, oututs_Ids] = actionNodeAst.nodeCall();
                        
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            node_name);
                        throw(ME);
                    end
                end
                isOneChildEntry = isequal(actionType, 'Entry') ...
                    && (nb_children == 1) && isempty(default_transition);
                for i=1:nb_children
                    % TODO: optimize the number of calls for nodes with the same output signature
                    if isequal(actionType, 'Entry')
                        action_node_name = ...
                            StateflowState_To_Lustre.getEntryActionNodeName(...
                            childrenNames{i}, childrenIDs{i});
                    else
                        action_node_name = ...
                            StateflowState_To_Lustre.getExitActionNodeName(...
                            childrenNames{i}, childrenIDs{i});
                    end
                    if ~isKey(SF_STATES_NODESAST_MAP, action_node_name)
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            action_node_name);
                        throw(ME);
                    end
                    actionNodeAst = SF_STATES_NODESAST_MAP(action_node_name);
                    if isequal(actionType, 'Entry')
                        [call, oututs_Ids] = actionNodeAst.nodeCall();
                    else
                        [call, oututs_Ids] = actionNodeAst.nodeCall(...
                            true, BooleanExpr(false));
                    end
                    if isOneChildEntry
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        cond = BinaryExpr(BinaryExpr.EQ, ...
                            idStateVar, IntExpr(childrenIDs{i}));
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                    
                end
                if isequal(actionType, 'Entry') ...
                        && nb_children == 0 && ...
                        (~isempty(state.InnerTransitions)...
                        || ~isempty(state.Composition.DefaultTransitions))
                    %State that contains only transitions and junctions
                    %inside
                    concurrent_actions{end+1} = LustreEq(idStateVar, IntExpr(-1));
                    inputs{end+1} = LustreVar(idStateVar, 'int');
                    outputs{end+1} = LustreVar(idStateVar, 'int');
                end
                
                if ~isempty(concurrent_actions)
                    actions{1} = ConcurrentAssignments(concurrent_actions);
                end
            end
        end
        
        %% state body
        function [outputs, inputs, body] = write_state_body(state)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            outputs = {};
            inputs = {};
            body = {};
            children_actions = {};
            parentPath = fileparts(state.Path);
            isChart = false;
            if isempty(parentPath)
                isChart = true;
            end
            idStateVar = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(state));
            if ~isChart
                %1st step: OuterTransition code
                outerTransNodeName = ...
                    StateflowState_To_Lustre.getStateOuterTransNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, outerTransNodeName)
                    nodeAst = SF_STATES_NODESAST_MAP(outerTransNodeName);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    body{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                end
                
                %2nd step: During actions
                idParentVar = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(...
                    SF_STATES_PATH_MAP(parentPath)));
                cond_prefix = BinaryExpr(BinaryExpr.EQ,...
                    idParentVar, IntExpr(state.Id));
                during_act_node_name = ...
                    StateflowState_To_Lustre.getDuringActionNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, during_act_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(during_act_node_name);
                    
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    inputs{end + 1} = LustreVar(idParentVar, 'int');
                end
                
                %3rd step: Inner transitions
                innerTransNodeName = ...
                    StateflowState_To_Lustre.getStateInnerTransNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, innerTransNodeName)
                    nodeAst = SF_STATES_NODESAST_MAP(innerTransNodeName);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    inputs{end + 1} = LustreVar(idParentVar, 'int');
                end
            else
                
                entry_act_node_name = ...
                    StateflowState_To_Lustre.getEntryActionNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, entry_act_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(entry_act_node_name);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    cond = BinaryExpr(BinaryExpr.EQ,...
                        idStateVar, IntExpr(0));
                    children_actions{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    inputs{end + 1} = LustreVar(idStateVar, 'int');
                end
                chart_prefix = BinaryExpr(BinaryExpr.NEQ,...
                    idStateVar, IntExpr(0));
                cond_prefix = {};
            end
            
            %4th step: execute the active child
            children = StateflowState_To_Lustre.getSubStatesObjects(state);
            number_children = numel(children);
            isParallel = isequal(state.Composition.Type, 'PARALLEL_AND');
            if number_children > 0 && ~isParallel
                inputs{1} = LustreVar(idStateVar, 'int');
            end
            for i=1:number_children
                child = children{i};
                cond = {};
                if ~isParallel
                    cond = ...
                        BinaryExpr(BinaryExpr.EQ, idStateVar, IntExpr(child.Id));
                    if ~isempty(cond_prefix)
                        cond = ...
                            BinaryExpr(BinaryExpr.AND, cond, cond_prefix);
                    end
                elseif isChart
                    cond = chart_prefix;
                end
                child_node_name = ...
                    StateflowState_To_Lustre.getStateNodeName(child);
                if isKey(SF_STATES_NODESAST_MAP, child_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(child_node_name);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    if isempty(cond)
                        children_actions{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getInputs()];
                    else
                        children_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getInputs()];
                    end
                end
            end
            if ~isempty(children_actions)
                body{end+1} = ConcurrentAssignments(children_actions);
            end
        end
        
        %% chart body
        function [outputs, inputs, variables, body] = write_chart_body(...
                parent, blk, chart, dataAndEvents, inputEvents)
            global SF_STATES_NODESAST_MAP;
            body = {};
            variables = {};
            
            %create inputs
            Scopes = cellfun(@(x) x.Scope, ...
                dataAndEvents, 'UniformOutput', false);
            inputsData = SF_To_LustreNode.orderObjects(...
                dataAndEvents(strcmp(Scopes, 'Input')), 'Port');
            inputs = cellfun(@(x) LustreVar(x.Name, x.LusDatatype), ...
                inputsData, 'UniformOutput', false);
            
            %create outputs
            outputsData = SF_To_LustreNode.orderObjects(...
                dataAndEvents(strcmp(Scopes, 'Output')), 'Port');
            outputs = cellfun(@(x) LustreVar(x.Name, x.LusDatatype), ...
                outputsData, 'UniformOutput', false);
            
            %get chart node AST
            if isempty(inputEvents)
                chartNodeName = ...
                    StateflowState_To_Lustre.getStateNodeName(chart);
            else
                chartNodeName = ...
                    StateflowState_To_Lustre.getChartEventsNodeName(chart);
            end
            if ~isKey(SF_STATES_NODESAST_MAP, chartNodeName)
                display_msg(...
                    sprintf('%s not found in SF_STATES_NODESAST_MAP',...
                    chartNodeName), ...
                    MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
                return;
            end
            nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
            [node_call, nodeCall_outputs_Ids] = nodeAst.nodeCall();
            nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_outputs_Ids, 'UniformOutput', false);
            nodeCall_inputs_Ids = node_call.getArgs();
            nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_inputs_Ids, 'UniformOutput', false);
            
            %local variables
            for i=1:numel(dataAndEvents)
                d = dataAndEvents{i};
                if isequal(d.Scope, 'Input')
                    continue;
                end
                d_name = d.Name;
                if ~ismember(d_name, nodeCall_outputs_Names) ...
                        &&  ~ismember(d_name, nodeCall_inputs_Names)
                    % not used
                    continue;
                end
                [v, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
                if status
                    display_msg(sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                        d.InitialValue, chart.Path), ...
                        MsgType.ERROR, 'Outport_To_Lustre', '');
                    v = 0;
                end
                if isequal(d.Scope, 'Parameter')
                    if isstruct(v) && isfield(v,'Value')
                        v = v.Value;
                    elseif isa(v, 'Simulink.Parameter')
                        v = v.Value;
                    end
                end
                IC_Var = SLX2LusUtils.num2LusExp(v, d.LusDatatype);
                
                if ~isequal(d.Scope, 'Output')
                    variables{end+1,1} = LustreVar(d_name, d.LusDatatype);
                end
                if isequal(d.Scope, 'Output')
                    d_firstName = strcat(d_name, '__1');
                    if ismember(d_name, nodeCall_inputs_Names)
                        body{end+1} = LustreEq(...
                            VarIdExpr(d_firstName), ...
                            BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                            UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_name))));
                        variables{end+1,1} = LustreVar(d_firstName, d.LusDatatype);
                        nodeCall_inputs_Ids = ...
                            StateflowState_To_Lustre.changeVar(...
                            nodeCall_inputs_Ids, d_name, d_firstName);
                    end
                elseif isequal(d.Scope, 'Local') 
                    d_lastName = strcat(d_name, '__2');
                    if ismember(d_name, nodeCall_outputs_Names)
                        body{end+1} = LustreEq(...
                            VarIdExpr(d_name), ...
                            BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                            UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_lastName))));
                        variables{end+1,1} = LustreVar(d_lastName, d.LusDatatype);
                        nodeCall_outputs_Ids = ...
                            StateflowState_To_Lustre.changeVar(...
                            nodeCall_outputs_Ids, d_name, d_lastName);
                    else
                        %local variable that was not modified in the chart
                        body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
                    end
                elseif isequal(d.Scope, 'Constant')
                    body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);  
                elseif isequal(d.Scope, 'Parameter')
                    body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);  
                end
            end
            
            %state IDs
            allVars = [variables; outputs; inputs];
            nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_inputs_Ids, 'UniformOutput', false);
            for i=1:numel(nodeCall_inputs_Names)
                v_name = nodeCall_inputs_Names{i};
                if ~VarIdExpr.ismemberVar(v_name, allVars)
                    if MatlabUtils.endsWith(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix())
                        %State ID
                        variables{end+1,1} = LustreVar(v_name, 'int');
                        if ismember(v_name, nodeCall_outputs_Names)
                            v_lastName = strcat(v_name, '__2');
                            body{end+1} = LustreEq(...
                                VarIdExpr(v_name), ...
                                BinaryExpr(BinaryExpr.ARROW, IntExpr(0), ...
                                UnaryExpr(UnaryExpr.PRE, VarIdExpr(v_lastName))));
                            variables{end+1,1} = LustreVar(v_lastName, 'int');
                            nodeCall_outputs_Ids = ...
                                StateflowState_To_Lustre.changeVar(...
                                nodeCall_outputs_Ids, v_name, v_lastName);
                        else
                            body{end+1} = LustreEq(VarIdExpr(v_name), IntExpr(0));
                        end
                    else
                        %UNKNOWN Variable
                        display_msg(sprintf('Variable %s in Chart %s not found',...
                            v_name, chart.Path), ...
                            MsgType.ERROR, 'Outport_To_Lustre', '');
                    end
                end
            end
            %update outputs names
            nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_outputs_Ids, 'UniformOutput', false);
            allVars = [variables; outputs; inputs];
            for i=1:numel(nodeCall_outputs_Names)
                v_name = nodeCall_outputs_Names{i};
                if ~VarIdExpr.ismemberVar(v_name, allVars)
                    if MatlabUtils.endsWith(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix())
                        variables{end+1,1} = LustreVar(v_name, 'int');
                    else
                        %UNKNOWN Variable
                        display_msg(sprintf('Variable %s in Chart %s not found',...
                            v_name, chart.Path), ...
                            MsgType.ERROR, 'Outport_To_Lustre', '');
                    end
                end
            end
            %Node Call
            node_call = NodeCallExpr(node_call.getNodeName(), nodeCall_inputs_Ids);
            body{end+1} = LustreEq(nodeCall_outputs_Ids, node_call);
        end
        
        %
        function [outputs, inputs, body] = ...
                write_ChartNodeWithEvents_body(chart, events)
            global SF_STATES_NODESAST_MAP;
            outputs = {};
            inputs = {};
            body = {};
            Scopes = cellfun(@(x) x.Scope, ...
                events, 'UniformOutput', false);
            inputEvents = SF_To_LustreNode.orderObjects(...
                events(strcmp(Scopes, 'Input')), 'Port');
            inputEventsNames = cellfun(@(x) x.Name, ...
                inputEvents, 'UniformOutput', false);
            inputEventsVars = cellfun(@(x) VarIdExpr(x.Name), ...
                inputEvents, 'UniformOutput', false);
            chartNodeName = ...
                StateflowState_To_Lustre.getStateNodeName(chart);
            if isKey(SF_STATES_NODESAST_MAP, chartNodeName)
                nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
                [orig_call, oututs_Ids] = nodeAst.nodeCall();
                outputs = [outputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getInputs()];
                for i=1:numel(inputEventsNames)
                    call = StateflowState_To_Lustre.changeEvents(...
                        orig_call, inputEventsNames, inputEventsNames{i});
                    cond_prefix = VarIdExpr(inputEventsNames{i});
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                end
                body{end+1} = LustreComment('If no event occured, time step wakes up the chart');
                allEventsCond = UnaryExpr(UnaryExpr.NOT, ...
                    BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, inputEventsVars));
                body{end+1} = LustreEq(oututs_Ids, ...
                    IteExpr(allEventsCond, orig_call, TupleExpr(oututs_Ids)));
            else
                display_msg(...
                    sprintf('%s not found in SF_STATES_NODESAST_MAP',...
                    chartNodeName), ...
                    MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
                return;
            end
        end
        function call = changeEvents(call, EventsNames, E)
            args = call.getArgs();
            inputs_Ids = cellfun(@(x) VarIdExpr(x.getId()), ...
                args, 'UniformOutput', false);
            for i=1:numel(inputs_Ids)
                if isequal(inputs_Ids{i}.getId(), E)
                    inputs_Ids{i} = BooleanExpr(true);
                elseif ismember(inputs_Ids{i}.getId(), EventsNames)
                    inputs_Ids{i} = BooleanExpr(false);
                end
            end
            
            call = NodeCallExpr(call.nodeName, inputs_Ids);
        end
        function params = changeVar(params, oldName, newName)
            for i=1:numel(params)
                if isequal(params{i}.getId(), oldName)
                    params{i} = VarIdExpr(newName);
                end
            end
        end
        %% Actions node name
        
        function name = getChartEventsNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_EventsNode');
        end
        
        function name = getStateNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_Node');
        end
        function name = getStateDefaultTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_DefaultTrans_Node');
        end
        function name = getStateInnerTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_InnerTrans_Node');
        end
        function name = getStateOuterTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_OuterTrans_Node');
        end
        function name = getEntryActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_EntryAction');
        end
        function name = getExitActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_ExitAction');
        end
        function name = getDuringActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_DuringAction');
        end
        function suf = getStateIDSuffix()
            suf = '__ChildID';
        end
        function idName = getStateIDName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            idName = strcat(state_name, ...
                StateflowState_To_Lustre.getStateIDSuffix());
        end
        
        %% Substates objects
        function subStates = getSubStatesObjects(state)
            global SF_STATES_PATH_MAP;
            childrenNames = state.Composition.Substates;
            subStates = cell(numel(childrenNames), 1);
            for i=1:numel(childrenNames)
                childPath = fullfile(state.Path, childrenNames{i});
                if ~isKey(SF_STATES_PATH_MAP, childPath)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', childPath);
                    throw(ME);
                end
                subStates{i} = SF_STATES_PATH_MAP(childPath);
            end
        end
    end
    
end

