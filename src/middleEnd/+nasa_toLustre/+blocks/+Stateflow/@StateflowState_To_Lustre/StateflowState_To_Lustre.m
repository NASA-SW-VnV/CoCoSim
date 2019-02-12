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
        %%
        function options = getUnsupportedOptions(state, varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% State Actions and DefaultTransitions Nodes
        [external_nodes, external_libraries ] = ...
            write_ActionsNodes(state, data_map)
        %% InnerTransitions and  OuterTransitions Nodes
        [external_nodes, external_libraries ] = ...
            write_TransitionsNodes(state, data_map)
        
        %% State Node
        main_node  = write_StateNode(state)
        
        %% Chart Node
        [main_node, external_nodes]  = write_ChartNode(parent, blk, chart, dataAndEvents, event_s)
        main_node  = write_ChartNodeWithEvents(chart, inputEvents)
        %% ENTRY ACTION
        [main_node, external_libraries] = ...
            write_entry_action(state, data_map)
        
        %% EXIT ACTION
        [main_node, external_libraries] = ...
            write_exit_action(state, data_map)
        
        %% DURING ACTION
        [main_node, external_libraries] = ...
            write_during_action(state, data_map)
        
        %% write_children_actions
        [actions, outputs, inputs] = ...
            write_children_actions(state, actionType)
        %% state body
        [outputs, inputs, body, variables] = write_state_body(state)
        
        %% chart body
        [outputs, inputs, variables, body] = write_chart_body(...
            parent, blk, chart, dataAndEvents, inputEvents)
        %
        [outputs, inputs, body] = ...
            write_ChartNodeWithEvents_body(chart, event_s)
        
        
        
        
        
        
        
    end
    
end

