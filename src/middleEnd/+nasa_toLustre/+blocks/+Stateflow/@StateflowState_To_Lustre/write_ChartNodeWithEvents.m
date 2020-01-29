
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function main_node  = write_ChartNodeWithEvents(chart, inputEvents)
    
    global SF_STATES_NODESAST_MAP;
    main_node = {};

    [outputs, inputs, body] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_ChartNodeWithEvents_body(chart, inputEvents);
    if isempty(body)
        %no code is required
        return;
    end
    %create the node
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getChartEventsNodeName(chart);
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(node_name);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Executing Events of state %s',...
        chart.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(node_name) = main_node;
end

