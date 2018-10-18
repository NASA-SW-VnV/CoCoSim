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
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_code(state)
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            %% Create State actions as external nodes that will be called by the states nodes.
            [action_nodes,  external_libraries_i] = ...
                StateflowState_To_Lustre.get_state_actions(state);
            external_nodes = [external_nodes, action_nodes];
            external_libraries = [external_libraries, external_libraries_i];
            %% Create transitions actions as external nodes that will be called by the states nodes.
            function addNodes(t, isDefaultTrans, parent_path)
                % Transition actions
                [transition_nodes_j, external_libraries_j ] = ...
                    StateflowTransition_To_Lustre.get_Actions(t, state, ...
                    isDefaultTrans);
                external_nodes = [external_nodes, transition_nodes_j];
                external_libraries = [external_libraries, external_libraries_j];
                % Transition node
                [transition_nodes_j, external_libraries_j ] = ...
                    StateflowTransition_To_Lustre.get_TransitionNode(t, state, isDefaultTrans, parent_path);
                external_nodes = [external_nodes, {transition_nodes_j}];
                external_libraries = [external_libraries, external_libraries_j];
            end
            
            T = state.Composition.DefaultTransitions;
            for i=1:numel(T)
                parentPath = state.Path;
                addNodes(T{i}, true, parentPath)
            end
            T = state.InnerTransitions;
            for i=1:numel(T)
                parentPath = state.Path;
                addNodes(T{i}, false, parentPath)
            end
            T = state.OuterTransitions;
            for i=1:numel(T)
                parentPath = fileparts(state.Path);
                addNodes(T{i}, false, parentPath)
            end
            %% Create state nodes if the states are not atomic.
            
            
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
        %ENTRY ACTION
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
            if isempty(parentName)
                %main chart
                return;
            end
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
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        %EXIT ACTION
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
                body{end+1} = LustreEq(VarIdExpr(idParentName), IntExpr(0));
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
        %DURING ACTION
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
            if nb_actions == 0
                return;
            end
            for i=1:nb_actions
                [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                    SF_To_LustreNode.getPseudoLusAction(actions{i});
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
            % Inner transitions
            %% TODO: code for inner transitions
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
            if isequal(state.Composition.Type, 'PARALLEL_AND')
                %% TODO
            else
                childrenNames = state.Composition.Substates;
                nb_children = numel(childrenNames);
                childrenIDs = state.Composition.States;
                idStateName = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(state));
                if nb_children >= 1
                    inputs{end+1} = LustreVar(idStateName, 'int');
                end
                default_transition = state.Composition.DefaultTransitions;
                if isequal(actionType, 'Entry')...
                        && ~isempty(default_transition)
                    % we need to get the default condition code, as the
                    % default transition decides what sub-state to enter while.
                    % entering the state. This is the case where stateId ==
                    % 0;
                    %% TODO: get_initial_state_code
                    
                end
                isOneChildEntry = isequal(actionType, 'Entry') ...
                    && (nb_children == 1) && isempty(default_transition);
                for i=1:nb_children
                    %% TODO: optimize the number of calls
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
                    [call, oututs_Ids] = actionNodeAst.nodeCall();
                    if isOneChildEntry
                        actions{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        cond = BinaryExpr(BinaryExpr.EQ, ...
                            idStateName, IntExpr(childrenIDs{i}));
                        actions{end+1} = LustreEq(oututs_Ids, ...
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
                    actions{end+1} = LustreEq(idStateName, IntExpr(-1));
                    inputs{end+1} = LustreVar(idStateName, 'int');
                    outputs{end+1} = LustreVar(idStateName, 'int');
                end
            end
        end
        %% Actions node name
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
        function idName = getStateIDName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            idName = strcat(state_name, '_ChildID');
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

