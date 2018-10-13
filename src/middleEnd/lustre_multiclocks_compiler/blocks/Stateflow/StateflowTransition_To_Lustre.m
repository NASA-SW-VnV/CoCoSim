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
        function [action_nodes, external_libraries ] = ...
                get_Actions(T, source_state, data)
            action_nodes = {};
            [ConditionAction_node, ConditionAction_external_nodes, ConditionActionext_ernal_libraries ] = ...
                StateflowTransition_To_Lustre.write_ConditionAction(T, source_state, data);
            if ~isempty(ConditionAction_node)
                action_nodes{end+1} = ConditionAction_node;
            end
            action_nodes = [action_nodes, ConditionAction_external_nodes];
            external_libraries = ConditionActionext_ernal_libraries;
            [TransitionAction_node, TransitionAction_external_nodes, TransitionAction_external_libraries ] = ...
                StateflowTransition_To_Lustre.write_TransitionAction(T, source_state, data);
            if ~isempty(TransitionAction_node)
                action_nodes{end+1} = TransitionAction_node;
            end
            action_nodes = [action_nodes, TransitionAction_external_nodes];
            external_libraries = [external_libraries, TransitionAction_external_libraries];
        end
        function  [main_node, external_nodes, external_libraries ] = ...
                write_ConditionAction(T, source_state, data)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, source_state, data, 'ConditionAction');
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_TransitionAction(T, source_state, data)
            [main_node, external_nodes, external_libraries ] = ...
                StateflowTransition_To_Lustre.write_Action(T, source_state, data, 'TransitionAction');
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action(T, source_state, data, type)
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            global SF_STATES_NODESAST_MAP;
            if isequal(type, 'ConditionAction')
                t_act_node_name = StateflowTransition_To_Lustre.getCondActionNodeName(T, source_state);
                action = T.ConditionAction;
            else
                t_act_node_name = StateflowTransition_To_Lustre.getTranActionNodeName(T, source_state);
                action = T.TransitionAction;
            end
            if isKey(SF_STATES_NODESAST_MAP, t_act_node_name)
                %already handled in StateflowState_To_Lustre
            else
                [main_node, external_nodes, external_libraries ] = ...
                    StateflowTransition_To_Lustre.write_Action_Node(action, data, t_act_node_name);
                if ~isempty(main_node)
                    comment = LustreComment(...
                        sprintf('Transition from %s to %s ExecutionOrder %d %s',...
                        source_state.Path, T.Destination.Name, ...
                        T.ExecutionOrder, type), true);
                    main_node.setMetaInfo(comment);
                end
            end
            
        end
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_Action_Node(action, data, t_act_node_name)
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            if iscell(action)
                action = action(~strcmp(action, ''));
            end
            if ~isempty(action)
                main_node = LustreNode();
                main_node.setName(t_act_node_name);
                %TODO parse action
            end
        end
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% Get unique short name
        function unique_name = getUniqueName(object, src)
            
            dst = object.Destination;
            id_str = sprintf('%.0f', object.ExecutionOrder);
            unique_name = sprintf('%s_To_%s_ExecutionOrder%s',...
                SF_To_LustreNode.getUniqueName(src),...
                SF_To_LustreNode.getUniqueName(dst), id_str );
            
        end
        function node_name = getCondActionNodeName(T, source_state)
            transition_prefix = StateflowTransition_To_Lustre.getUniqueName(T, source_state);
            node_name = sprintf('%s_Cond_Act', transition_prefix);
        end
        function node_name = getTranActionNodeName(T, source_state)
            transition_prefix = StateflowTransition_To_Lustre.getUniqueName(T, source_state);
            node_name = sprintf('%s_Tran_Act', transition_prefix);
        end
    end
    
end

