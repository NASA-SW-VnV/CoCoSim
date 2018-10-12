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
                write_code(state, data, events)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            %% Create transitions actions:
            % default transition
            T = [state.Composition.DefaultTransitions, ...
                state.OuterTransitions,...
                state.InnerTransitions];
            for i=1:numel(T)
                transition_prefix = StateflowTransition_To_Lustre.getUniqueName(T{i}, state);
                t_cond_act_name = sprintf('%s_Cond_Act', transition_prefix);
                if isKey(SF_STATES_NODESAST_MAP, t_cond_act_name)
                    %already handled in StateflowState_To_Lustre
                    continue;
                else
                    [node_i, external_nodes_i, external_libraries_i ] = ...
                        StateflowTransition_To_Lustre.write_action(T{i}, t_cond_act_name);
                    if iscell(node_i)
                        external_nodes = [external_nodes, node_i];
                    else
                        external_nodes{end+1} = node_i;
                    end
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, external_libraries_i];
                end
            end
        end
        
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

