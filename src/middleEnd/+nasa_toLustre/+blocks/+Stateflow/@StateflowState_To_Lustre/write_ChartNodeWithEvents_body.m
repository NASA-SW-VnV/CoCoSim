%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [outputs, inputs, body] = ...
        write_ChartNodeWithEvents_body(chart, events)
    global SF_STATES_NODESAST_MAP;
    
    outputs = {};
    inputs = {};
    body = {};
    Scopes = cellfun(@(x) x.Scope, ...
        events, 'UniformOutput', false);
    inputEvents = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        events(strcmp(Scopes, 'Input')), 'Port');
    inputEventsNames = cellfun(@(x) x.Name, ...
        inputEvents, 'UniformOutput', false);
    inputEventsVars = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.Name), ...
        inputEvents, 'UniformOutput', false);
    chartNodeName = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.getStateNodeName(chart);
    if isKey(SF_STATES_NODESAST_MAP, chartNodeName)
        nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
        [orig_call, oututs_Ids] = nodeAst.nodeCall();
        outputs = [outputs, nodeAst.getOutputs()];
        inputs = [inputs, nodeAst.getOutputs()];
        inputs = [inputs, nodeAst.getInputs()];
        for i=1:numel(inputEventsNames)
            call = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeEvents(...
                orig_call, inputEventsNames, inputEventsNames{i});
            cond_prefix = nasa_toLustre.lustreAst.VarIdExpr(inputEventsNames{i});
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                nasa_toLustre.lustreAst.IteExpr(cond_prefix, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
        end
        %NOT CORRECT
        % body{end+1} = nasa_toLustre.lustreAst.LustreComment('If no event occured, time step wakes up the chart');
        % allEventsCond = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
        %     nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, inputEventsVars));
        % body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
        %     nasa_toLustre.lustreAst.IteExpr(allEventsCond, orig_call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
    else
        display_msg(...
            sprintf('%s not found in SF_STATES_NODESAST_MAP',...
            chartNodeName), ...
            MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
        return;
    end
end
