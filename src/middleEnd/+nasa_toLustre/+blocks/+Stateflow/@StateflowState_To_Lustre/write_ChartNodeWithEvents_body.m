%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateNodeName(chart);
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
