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
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP SF_DATA_MAP;
            %It's initialized for each call of this function
            SF_STATES_NODESAST_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_STATES_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_DATA_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            %% get content
            content = blk.StateflowContent;
            events = SF_To_LustreNode.eventsToData(content.Events);
            data = [events, content.Data];
            for i=1:numel(data)
                SF_DATA_MAP(data{i}.Name) = data{i};
            end
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
                    
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of state %s failed', ...
                        states{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
        end
        %%
        %% Get unique short name
        function unique_name = getUniqueName(object, id)
            if ischar(object) && nargin == 2
                name = object;
            else
                name = object.Name;
                id = object.Id;
            end
            [~, name, ~] = fileparts(name);
            id_str = sprintf('%.0f', id);
            unique_name = sprintf('%s_%s',SLX2LusUtils.name_format(name),id_str );
        end
        %% Order states
        function ordered = orderStates(states)
            levels = cellfun(@(x) numel(regexp(x.Path, '/', 'split')), ...
                states, 'UniformOutput', true);
            [~, I] = sort(levels, 'descend');
            ordered = states(I);
        end
        %% change events to data
        function data = eventsToData(events)
            data = {};
            for i=1:numel(events)
                data{i} = events{i};
                data{i}.Datatype = 'bool';
                data{i}.CompiledType = 'boolean';
                data{i}.InitialValue = 'false';
                data{i}.ArraySize = '-1';
            end
        end
        %% Action to Lustre
        function [lus_action, outputs, inputs, external_libraries] = getPseudoLusAction(action, isCondition)
            if nargin < 2
                isCondition = false;
            end
            [tree, status, unsupportedExp] = Fcn_Exp_Parser(action);
            outputs = {};
            inputs = {};
            if status
                ME = MException('COCOSIM:STATEFLOW', ...
                    'ParseError  character unsupported  %s in Action %s in StateFlow.', ...
                    unsupportedExp, action);
                throw(ME);
            end
            obj = DummyBlock_To_Lustre();
            try
                lus_action = Fcn_To_Lustre.tree2code(obj, tree, [], [], [], [], true);
                external_libraries = obj.getExternalLibraries();
            catch me
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    ME = MException('COCOSIM:STATEFLOW', ...
                        '%s in Action %s', ...
                        me.message, action);
                    throw(ME);
                else
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'Parsing Action "%s" has failed', action);
                    throw(ME);
                end
            end
            if ~isCondition && ~isa(lus_action, 'LustreEq')
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" should be an assignement (e.g. outputs = f(inputs))', lus_action);
                throw(ME);
            end
            if isCondition
                inputs_names = lus_action.GetVarIds();
                outputs_names = {};
            else
                [outputs_names, inputs_names] = lus_action.GetVarIds();
            end
            outputs_names = unique(outputs_names);
            inputs_names = unique(inputs_names);
            global SF_DATA_MAP;
            for i=1:numel(outputs_names)
                k = outputs_names{i};
                if isKey(SF_DATA_MAP, k)
                    outputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).Datatype);
                else
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'Variable %s can not be found for state "%s"', ...
                        k, state.Path);
                    throw(ME);
                end
            end
            for i=1:numel(inputs_names)
                k = inputs_names{i};
                if isKey(SF_DATA_MAP, k)
                    inputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).Datatype);
                else
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'Variable %s can not be found for state "%s"', ...
                        k, state.Path);
                    throw(ME);
                end
            end
        end
    end
end