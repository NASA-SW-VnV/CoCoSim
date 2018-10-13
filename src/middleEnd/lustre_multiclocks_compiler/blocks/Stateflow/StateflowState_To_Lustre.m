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
                write_code(state, data)
            global SF_STATES_NODESAST_MAP ;
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            %% Create State actions
            [action_nodes,  external_libraries_i] = ...
                StateflowState_To_Lustre.get_state_actions(state, data);
            external_nodes = [external_nodes, action_nodes];
            external_libraries = [external_libraries, external_libraries_i];
            %% Create transitions actions:
            T = [state.Composition.DefaultTransitions, ...
                state.OuterTransitions,...
                state.InnerTransitions];
            for i=1:numel(T)
                [transition_nodes_i, external_libraries_i ] = ...
                    StateflowTransition_To_Lustre.get_Actions(T{i}, state, data);
                external_nodes = [external_nodes, transition_nodes_i];
                external_libraries = [external_libraries, external_libraries_i];
            end
            
            
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
                get_state_actions(state, data)
            action_nodes = {};
            %write_entry_action
            [entry_action_node, external_libraries] = ...
                StateflowState_To_Lustre.write_entry_action(state, data);
            if ~isempty(entry_action_node)
                action_nodes{end+1} = entry_action_node;
            end
            %write_exit_action
            [exit_action_node, ext_lib] = ...
                StateflowState_To_Lustre.write_exit_action(state, data);
            if ~isempty(exit_action_node)
                action_nodes{end+1} = exit_action_node;
            end
            %write_during_action
            external_libraries = [external_libraries, ext_lib];
            [during_action_node, ext_lib2] = ...
                StateflowState_To_Lustre.write_during_action(state, data);
            if ~isempty(during_action_node)
                action_nodes{end+1} = during_action_node;
            end
            external_libraries = [external_libraries, ext_lib2];
        end
        %ENTRY ACTION
        function [main_node, external_libraries] = ...
                write_entry_action(state, data)
            global SF_STATES_PATH_MAP;
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
            body{1} = LustreComment('-- set state as active');
            body{2} = LustreEq(VarIdExpr(idParentName), IntExpr(state.Id));
            outputs{1} = LustreVar(idParentName, 'int');
            
            %actions code
            actions = SFIRPPUtils.split_actions(state.Actions.Entry);
            nb_actions = numel(actions);
            for i=1:nb_actions
                
            end
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getEntryActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('Entre action of state %s',...
                state.Path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            main_node.setOutputs(outputs);
            
        end
        %EXIT ACTION
        function [main_node, external_libraries] = ...
                write_exit_action(state, data)
            main_node = {};
            external_libraries = {};
            actions = SFIRPPUtils.split_actions(state.Actions.Exit);
            if ~isempty(actions)
                act_node_name = ...
                    StateflowState_To_Lustre.getExitActionNodeName(state);
                main_node = LustreNode();
                main_node.setName(act_node_name);
                comment = LustreComment(...
                    sprintf('Exit action of state %s',...
                    state.Path), true);
                main_node.setMetaInfo(comment);
                %TODO parse action
            end
        end
        %DURING ACTION
        function [main_node, external_libraries] = ...
                write_during_action(state, data)
            main_node = {};
            external_libraries = {};
            actions = SFIRPPUtils.split_actions(state.Actions.During);
            if ~isempty(actions)
                act_node_name = ...
                    StateflowState_To_Lustre.getDuringActionNodeName(state);
                main_node = LustreNode();
                main_node.setName(act_node_name);
                comment = LustreComment(...
                    sprintf('During action of state %s',...
                    state.Path), true);
                main_node.setMetaInfo(comment);
                %TODO parse action
            end
        end
        %% Actions node name
        function name = getEntryActionNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_EntryAction');
        end
        function name = getExitActionNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_ExitAction');
        end
        function name = getDuringActionNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_DuringAction');
        end
        function idName = getStateIDName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            idName = strcat(state_name, '_ChildID');
        end
    end
    
end

