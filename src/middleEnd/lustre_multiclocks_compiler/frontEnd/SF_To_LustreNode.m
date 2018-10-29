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
                chart2node(parent,  chart,  main_sampleTime, backend, xml_trace)
            %the main function
            % initialize outputs
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            % global varibale mapping between states and their nodes AST.
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP SF_JUNCTIONS_PATH_MAP SF_DATA_MAP;
            %It's initialized for each call of this function
            SF_STATES_NODESAST_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_STATES_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_JUNCTIONS_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_DATA_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');

            % get content
            content = chart.StateflowContent;
            events = SF_To_LustreNode.eventsToData(content.Events);
            dataAndEvents = [events; content.Data];
            for i=1:numel(dataAndEvents)
                SF_DATA_MAP(dataAndEvents{i}.Name) = dataAndEvents{i};
            end
            states = SF_To_LustreNode.orderObjects(content.States);
            for i=1:numel(states)
                SF_STATES_PATH_MAP(states{i}.Path) = states{i};
            end
            junctions = content.Junctions;
            for i=1:numel(junctions)
                SF_JUNCTIONS_PATH_MAP(junctions{i}.Path) = junctions{i};
            end
            % Go Over Stateflow Functions
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
            
            % Go over Junctions Outertransitions: condition/Transition Actions
            for i=1:numel(junctions)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowJunction_To_Lustre.write_code(junctions{i});
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, external_libraries_i];
                catch me
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of Junction %s failed', ...
                        junctions{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            
            % Go over states: for state actions
            for i=1:numel(states)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowState_To_Lustre.write_ActionsNodes(states{i});
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, ...
                        external_libraries_i];
                catch me
                    
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR,...
                            'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, ...
                            'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of state %s failed', ...
                        states{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            % Go over states: for state Transitions
            % the previous loop should be performed before this one so all
            % state actions signature are stored.
            for i=1:numel(states)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowState_To_Lustre.write_TransitionsNodes(...
                        states{i});
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, ...
                        external_libraries_i];
                catch me
                    
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, ...
                            'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, ...
                            'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of state %s failed', ...
                        states{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            
            % Go over states for state Nodes
            for i=1:numel(states)
                try
                    node = StateflowState_To_Lustre.write_StateNode(...
                        states{i});
                    if ~isempty(node)
                        external_nodes{end+1} = node;
                    end
                catch me
                    
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, ...
                            'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, ...
                            'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of state %s failed', ...
                        states{i}.Path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            
            %Chart node
            [main_node, external_nodes_i] =...
                StateflowState_To_Lustre.write_ChartNode(parent, chart, states{end}, dataAndEvents, events);
            external_nodes = [external_nodes, ...
                external_nodes_i];
            
            %change from imperative code to Lustre
            %main_node = main_node.pseudoCode2Lustre();% already handled
            for i=1:numel(external_nodes)
                external_nodes{i} = external_nodes{i}.pseudoCode2Lustre();
            end
        end
        %%
        %% Get unique short name
        function unique_name = getUniqueName(object, id)
            global SF_STATES_PATH_MAP SF_JUNCTIONS_PATH_MAP;
            if ischar(object) 
                name = object;
                if nargin == 1
                    if isKey(SF_STATES_PATH_MAP, name)
                        id = SF_STATES_PATH_MAP(name).Id;
                    elseif isKey(SF_JUNCTIONS_PATH_MAP, name)
                        id = SF_JUNCTIONS_PATH_MAP(name).Id;
                    else
                        error('%s not found in SF_STATES_PATH_MAP', name);
                    end
                end
            else
                name = object.Name;
                id = object.Id;
            end
            [~, name, ~] = fileparts(name);
            id_str = sprintf('%.0f', id);
            unique_name = sprintf('%s_%s',SLX2LusUtils.name_format(name),id_str );
        end
        function v = virtualVarStr()
            v = '_SFvirtual';
        end
        %% Order states, transitions ...
        function ordered = orderObjects(objects, fieldName)
            if nargin == 1
                fieldName = 'Path';
            end
            if isequal(fieldName, 'Path')
                levels = cellfun(@(x) numel(regexp(x.Path, '/', 'split')), ...
                    objects, 'UniformOutput', true);
                [~, I] = sort(levels, 'descend');
                ordered = objects(I);
            elseif isequal(fieldName, 'ExecutionOrder') ...
                    || isequal(fieldName, 'Port')
                orders = cellfun(@(x) x.(fieldName), ...
                    objects, 'UniformOutput', true);
                [~, I] = sort(orders);
                ordered = objects(I);
            end
        end
        %% change events to data
        function data = eventsToData(events)
            data = cell(numel(events), 1);
            for i=1:numel(events)
                data{i} = events{i};
                if isequal(data{i}.Scope, 'Input')
                    data{i}.Port = data{i}.Port - numel(events);%for ordering reasons
                end
                data{i}.LusDatatype = 'bool';
                data{i}.Datatype = 'Event';
                data{i}.CompiledType = 'boolean';
                data{i}.InitialValue = 'false';
                data{i}.ArraySize = '-1';
            end
        end
        %% Action to Lustre
        function [lus_action, outputs, inputs, external_libraries] = getPseudoLusAction(action, isCondition, ignoreOutInputs)
            if nargin < 2
                isCondition = false;
            end
            if nargin < 3
                ignoreOutInputs = false;
            end
            action = strrep(action, ';', '');
            [tree, status, unsupportedExp] = Fcn_Exp_Parser.parse(action);
            outputs = {};
            inputs = {};
            if status
                ME = MException('COCOSIM:STATEFLOW', ...
                    'ParseError: unsupported expression "%s" in Action %s in StateFlow.', ...
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
                    display_msg(me.getReport(), MsgType.DEBUG, 'getPseudoLusAction', '');
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'Parsing Action "%s" has failed', action);
                    throw(ME);
                end
            end
            if isempty(lus_action)
                return;
            end
            if ~isCondition && ~isa(lus_action, 'LustreEq')
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" should be an assignement (e.g. outputs = f(inputs))', action);
                throw(ME);
            end
            %this flag is used by unitTests.
            if ignoreOutInputs
                return;
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
                    outputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).LusDatatype);
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
                    inputs{end + 1} = LustreVar(k, SF_DATA_MAP(k).LusDatatype);
                else
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'Variable %s can not be found for Action "%s"', ...
                        k, action);
                    throw(ME);
                end
            end
        end
    end
end