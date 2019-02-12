
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
    events = SF2LusUtils.eventsToData(content.Events);
    dataAndEvents = [events; content.Data];
    for i=1:numel(dataAndEvents)
        SF_DATA_MAP(dataAndEvents{i}.Name) = dataAndEvents{i};
    end
    SF_DATA_MAP = SF2LusUtils.addArrayData(SF_DATA_MAP, dataAndEvents);
    states = SF2LusUtils.orderObjects(content.States);
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

