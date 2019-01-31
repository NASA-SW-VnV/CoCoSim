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
                chart2node(parent,  chart,  main_sampleTime, lus_backend, xml_trace)
            %the main function
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % global varibale mapping between states and their nodes AST.
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP ...
                SF_JUNCTIONS_PATH_MAP SF_STATES_ENUMS_MAP ...
                SF_GRAPHICALFUNCTIONS_MAP TOLUSTRE_ENUMS_MAP;
            %It's initialized for each call of this function
            SF_STATES_NODESAST_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_STATES_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_JUNCTIONS_PATH_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_STATES_ENUMS_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_GRAPHICALFUNCTIONS_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            SF_DATA_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            % initialize outputs
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            
            % get content
            content = chart.StateflowContent;
            events = SF_To_LustreNode.eventsToData(content.Events);
            dataAndEvents = [events; content.Data];
            for i=1:numel(dataAndEvents)
                SF_DATA_MAP(dataAndEvents{i}.Name) = dataAndEvents{i};
            end
            SF_DATA_MAP = SF_To_LustreNode.addArrayData(SF_DATA_MAP, dataAndEvents);
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
                    sfunc = SFFunctions{i};
                    try
                        [node_i, external_nodes_i, external_libraries_i ] = ...
                            StateflowGraphicalFunction_To_Lustre.write_code(...
                            sfunc, SF_DATA_MAP);
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
                        display_msg(sprintf('Translation of Stateflow Function %s failed', ...
                            sfunc.Origin_path),...
                            MsgType.ERROR, 'SF_To_LustreNode', '');
                    end
                    
                end
            end
            
            % Go over Truthtables
            if isfield(content, 'TruthTables')
                truthTables = content.TruthTables;
                for i=1:numel(truthTables)
                    table = truthTables{i};
                    try
                        [node_i, external_nodes_i, external_libraries_i ] = ...
                            StateflowTruthTable_To_Lustre.write_code(...
                            table, SF_DATA_MAP, content);
                        if iscell(node_i)
                            external_nodes = [external_nodes, node_i];
                        else
                            external_nodes{end+1} = node_i;
                        end
                        external_nodes = [external_nodes, external_nodes_i];
                        external_libraries = [external_libraries, external_libraries_i];
                    catch me
                        
                        if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                            display_msg(me.message, MsgType.ERROR,...
                                'SF_To_LustreNode', '');
                        else
                            display_msg(me.getReport(), MsgType.DEBUG, ...
                                'SF_To_LustreNode', '');
                        end
                        display_msg(sprintf('Translation of TruthTable %s failed', ...
                            table.Path),...
                            MsgType.ERROR, 'SF_To_LustreNode', '');
                    end
                end
            end
            % Go over Junctions Outertransitions: condition/Transition Actions
            for i=1:numel(junctions)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowJunction_To_Lustre.write_code(junctions{i}, SF_DATA_MAP);
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, external_libraries_i];
                catch me
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of Junction %s failed', ...
                        junctions{i}.Origin_path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            
            % Go over states: for state actions
            for i=1:numel(states)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowState_To_Lustre.write_ActionsNodes(...
                        states{i}, SF_DATA_MAP);
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
                        states{i}.Origin_path),...
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
                        states{i}, SF_DATA_MAP);
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
                        states{i}.Origin_path),...
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
                        states{i}.Origin_path),...
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
            
            % add Stateflow Enumerations to ToLustre set of enumerations.
            keys = SF_STATES_ENUMS_MAP.keys();
            for i=1:numel(keys)
                TOLUSTRE_ENUMS_MAP(keys{i}) = ...
                    cellfun(@(x) EnumValueExpr(x), SF_STATES_ENUMS_MAP(keys{i}), ...
                    'UniformOutput', false);
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
            unique_name = sprintf('%s_%s',...
                nasa_toLustre.utils.SLX2LusUtils.name_format(name),id_str );
        end
        
        %% special Var Names
        function v = virtualVarStr()
            v = '_SFvirtual';
        end
        function v = isInnerStr()
            v = '_isInner';
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
                data{i}.ArraySize = '1';
                data{i}.CompiledSize = '1';
            end
        end
        function vars = getDataVars(d_list)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            vars = {};
            for i=1:numel(d_list)
                names = SF_To_LustreNode.getDataName(d_list{i});
                lusDt = d_list{i}.LusDatatype;
                vars = MatlabUtils.concat(vars, ...
                    cellfun(@(x) LustreVar(x, lusDt), ...
                    names, 'UniformOutput', false));
            end
        end
        function names = getDataName(d)
            if isfield(d, 'CompiledSize')
                CompiledSize = str2num(d.CompiledSize);
            elseif isfield(d, 'ArraySize')
                CompiledSize = str2num(d.ArraySize);
            else
                CompiledSize = 1;
            end
            CompiledSize = prod(CompiledSize);
            if CompiledSize == 1 || CompiledSize == -1
                names = {d.Name};
            else
                for i=1:CompiledSize
                    names{i} = sprintf('%s__ID%.0f_Index%d', d.Name, d.Id, i);
                end
            end
        end
        function SF_DATA_MAP = addArrayData(SF_DATA_MAP, d_list)
            import nasa_toLustre.frontEnd.SF_To_LustreNode
            for i=1:numel(d_list)
                names = SF_To_LustreNode.getDataName(d_list{i});
                if numel(names) > 1
                    for j=1:numel(names)
                        d = d_list{i};
                        d.Name = names{j};
                        d.ArraySize = '1';
                        d.CompiledSize = '1';
                        try
                            [v, ~, ~] = ...
                                SLXUtils.evalParam(gcs, [], [], d.InitialValue);
                        catch
                            v = 0;
                        end
                        if numel(v) >= j
                            v = v(j);
                        else
                            v = v(1);
                        end
                        d.InitialValue = num2str(v);
                        SF_DATA_MAP(names{j}) = d;
                    end
                end
            end
        end
    end
end