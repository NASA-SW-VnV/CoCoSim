%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [outputs, inputs, body] = ...
        write_ChartNodeWithEvents_body(chart, events)
    global SF_STATES_NODESAST_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    outputs = {};
    inputs = {};
    body = {};
    Scopes = cellfun(@(x) x.Scope, ...
        events, 'UniformOutput', false);
    inputEvents = SF_To_LustreNode.orderObjects(...
        events(strcmp(Scopes, 'Input')), 'Port');
    inputEventsNames = cellfun(@(x) x.Name, ...
        inputEvents, 'UniformOutput', false);
    inputEventsVars = cellfun(@(x) VarIdExpr(x.Name), ...
        inputEvents, 'UniformOutput', false);
    chartNodeName = ...
        StateflowState_To_Lustre.getStateNodeName(chart);
    if isKey(SF_STATES_NODESAST_MAP, chartNodeName)
        nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
        [orig_call, oututs_Ids] = nodeAst.nodeCall();
        outputs = [outputs, nodeAst.getOutputs()];
        inputs = [inputs, nodeAst.getOutputs()];
        inputs = [inputs, nodeAst.getInputs()];
        for i=1:numel(inputEventsNames)
            call = SF2LusUtils.changeEvents(...
                orig_call, inputEventsNames, inputEventsNames{i});
            cond_prefix = VarIdExpr(inputEventsNames{i});
            body{end+1} = LustreEq(oututs_Ids, ...
                IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
        end
        %NOT CORRECT
        % body{end+1} = LustreComment('If no event occured, time step wakes up the chart');
        % allEventsCond = UnaryExpr(UnaryExpr.NOT, ...
        %     BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, inputEventsVars));
        % body{end+1} = LustreEq(oututs_Ids, ...
        %     IteExpr(allEventsCond, orig_call, TupleExpr(oututs_Ids)));
    else
        display_msg(...
            sprintf('%s not found in SF_STATES_NODESAST_MAP',...
            chartNodeName), ...
            MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
        return;
    end
end