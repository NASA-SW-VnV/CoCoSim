classdef SF_To_LustreNode
    %SF_To_LustreNode translates a Stateflow chart to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        function [main_node, external_nodes, external_libraries ] = ...
                chart2node(parent,  blk,  main_sampleTime, backend, xml_trace)
            %the main function
            %% initialize outputs
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            %% global varibale mapping between states and their nodes AST.
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            %It's initialized for each call of this function
            SF_STATES_NODESAST_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_STATES_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            %% get content
            content = blk.StateflowContent;
            events = content.Events;
            data = content.Data;
            states = SF_To_LustreNode.orderStates(content.States);
            for i=1:numel(states)
                SF_STATES_PATH_MAP(states{i}.Path) = states{i};
            end
            %% Go Over Stateflow Functions
            if isfield(content, 'GraphicalFunctions')
                SFFunctions = content.GraphicalFunctions;
                for i=1:numel(SFFunctions)
                    sf_name = SF_To_LustreNode.getUniqueName(SFFunctions{i});
                    if isKey(SF_STATES_NODESAST_MAP, sf_name)
                        %already handled
                        continue;
                    else
                        [node_i, external_nodes_i, external_libraries_i ] = ...
                            StateflowFunction_To_Lustre.write_code();
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
            
            %% Go over states
            for i=1:numel(states)
                try
                    [node_i, external_nodes_i, external_libraries_i ] = ...
                        StateflowState_To_Lustre.write_code(states{i}, data);
                    if iscell(node_i)
                        external_nodes = [external_nodes, node_i];
                    else
                        external_nodes{end+1} = node_i;
                    end
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, external_libraries_i];
                catch me
                    display_msg(sprintf('Translation of state %s failed', ...
                        states{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'Fcn_To_Lustre', '');
                    else
                        display_msg(me.message, MsgType.DEBUG, 'Fcn_To_Lustre', '');
                    end
                end
            end
        end
        %%
        %% Get unique short name
        function unique_name = getUniqueName(object)
            [~, name, ~] = fileparts(object.Name);
            id_str = sprintf('%.0f', object.Id);
            unique_name = sprintf('%s_%s',SLX2LusUtils.name_format(name),id_str );
        end
        %% Order states
        function ordered = orderStates(states)
            levels = cellfun(@(x) numel(regexp(x.Path, '/', 'split')), ...
                states, 'UniformOutput', true);
            [~, I] = sort(levels, 'descend');
            ordered = states(I);
        end
        
    end
end