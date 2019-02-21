%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Chart Node
function [main_node, external_nodes]  = write_ChartNode(parent, blk, chart, dataAndEvents, events)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP;
    external_nodes = {};
    Scopes = cellfun(@(x) x.Scope, ...
        events, 'UniformOutput', false);
    inputEvents = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        events(strcmp(Scopes, 'Input')), 'Port');
    if ~isempty(inputEvents)
        %create a node that do the multi call for each event
        eventNode  = ...
            StateflowState_To_Lustre.write_ChartNodeWithEvents(...
            chart, inputEvents);
        external_nodes{1} = eventNode;
    end
    [outputs, inputs, variable, body] = ...
        StateflowState_To_Lustre.write_chart_body(parent, blk, chart, dataAndEvents, inputEvents);

    %create the node
    node_name = ...
       nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    main_node = LustreNode();
    main_node.setName(node_name);
    comment = LustreComment(sprintf('Chart Node: %s', chart.Origin_path),...
        true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);            
    main_node.setOutputs(outputs);
    if isempty(inputs)
        inputs{1} = ...
            LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    end
    main_node.setInputs(inputs);

    main_node.setLocalVars(variable);
    SF_STATES_NODESAST_MAP(node_name) = main_node;
end

