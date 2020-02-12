
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
%% chart body
function [outputs, inputs, variables, body] = write_chart_body(...
        parent, blk, chart, dataAndEvents, inputEvents)
    global SF_STATES_NODESAST_MAP;
    
    body = {};
    variables = {};

    %create inputs
    Scopes = cellfun(@(x) x.Scope, ...
        dataAndEvents, 'UniformOutput', false);
    inputsData = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        dataAndEvents(strcmp(Scopes, 'Input')), 'Port');
    inputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(inputsData);

    %create outputs
    outputsData = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        dataAndEvents(strcmp(Scopes, 'Output')), 'Port');
    outputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(outputsData);

    %get chart node AST
    if isempty(inputEvents)
        chartNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateNodeName(chart);
    else
        chartNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getChartEventsNodeName(chart);
    end
    if ~isKey(SF_STATES_NODESAST_MAP, chartNodeName)
        display_msg(...
            sprintf('%s not found in SF_STATES_NODESAST_MAP',...
            chartNodeName), ...
            MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
        return;
    end
    nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
    [node_call, nodeCall_outputs_Ids] = nodeAst.nodeCall();
    nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
        nodeCall_outputs_Ids, 'UniformOutput', false);
    nodeCall_inputs_Ids = node_call.getArgs();
    nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
        nodeCall_inputs_Ids, 'UniformOutput', false);

    %local variables
    for i=1:numel(dataAndEvents)
        d = dataAndEvents{i};
        if strcmp(d.Scope, 'Input')
            continue;
        end
        d_names = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataName(d);
        for j=1:numel(d_names)
            d_name = d_names{j};
            if ~ismember(d_name, nodeCall_outputs_Names) ...
                    &&  ~ismember(d_name, nodeCall_inputs_Names)
                % not used
                continue;
            end
            [v, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
            if status
                display_msg(sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                    d.InitialValue, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
                v = 0;
            end
            if strcmp(d.Scope, 'Parameter')
                if isstruct(v) && isfield(v,'Value')
                    v = v.Value;
                elseif isa(v, 'Simulink.Parameter')
                    v = v.Value;
                end
            end
            if numel(v) >= j
                v = v(j);
            else
                v = v(1);
            end
            IC_Var =nasa_toLustre.utils.SLX2LusUtils.num2LusExp(v, d.LusDatatype);

            if ~strcmp(d.Scope, 'Output')
                variables{end+1} = nasa_toLustre.lustreAst.LustreVar(d_name, d.LusDatatype);
            end
            if strcmp(d.Scope, 'Output')
                d_firstName = strcat(d_name, '__1');
                if ismember(d_name, nodeCall_inputs_Names)
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                        nasa_toLustre.lustreAst.VarIdExpr(d_firstName), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, IC_Var, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(d_name))));
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(d_firstName, d.LusDatatype);
                    nodeCall_inputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_inputs_Ids, d_name, d_firstName);
                end
            elseif strcmp(d.Scope, 'Local')
                d_lastName = strcat(d_name, '__2');
                if ismember(d_name, nodeCall_outputs_Names)
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                        nasa_toLustre.lustreAst.VarIdExpr(d_name), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, IC_Var, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(d_lastName))));
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(d_lastName, d.LusDatatype);
                    nodeCall_outputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_outputs_Ids, d_name, d_lastName);
                else
                    %local variable that was not modified in the chart
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(d_name), IC_Var);
                end
            elseif strcmp(d.Scope, 'Constant')
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(d_name), IC_Var);
            elseif strcmp(d.Scope, 'Parameter')
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(d_name), IC_Var);
            end
        end
    end

    %state IDs
    allVars = coco_nasa_utils.MatlabUtils.concat(variables, outputs, inputs);
    nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
        nodeCall_inputs_Ids, 'UniformOutput', false);
    for i=1:numel(nodeCall_inputs_Names)
        v_name = nodeCall_inputs_Names{i};
        if ~nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(v_name, allVars)
            if coco_nasa_utils.MatlabUtils.endsWith(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix())
                %State ID
                v_type = strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateEnumSuffix());
                v_inactive = nasa_toLustre.lustreAst.VarIdExpr(upper(...
                    strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    '_INACTIVE')));
                variables{end+1} = nasa_toLustre.lustreAst.LustreVar(v_name, v_type);
                if ismember(v_name, nodeCall_outputs_Names)
                    v_lastName = strcat(v_name, '__2');
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                        nasa_toLustre.lustreAst.VarIdExpr(v_name), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, v_inactive, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(v_lastName))));
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(v_lastName, v_type);
                    nodeCall_outputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_outputs_Ids, v_name, v_lastName);
                else
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(v_name), v_inactive);
                end
            else
                %UNKNOWN Variable
                display_msg(sprintf('Variable %s in Chart %s not found',...
                    v_name, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
            end
        end
    end
    %update outputs names
    nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
        nodeCall_outputs_Ids, 'UniformOutput', false);
    allVars = coco_nasa_utils.MatlabUtils.concat(variables, outputs, inputs);
    for i=1:numel(nodeCall_outputs_Names)
        v_name = nodeCall_outputs_Names{i};
        if ~nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(v_name, allVars)
            if coco_nasa_utils.MatlabUtils.endsWith(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix())
                v_type = strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateEnumSuffix());
                variables{end+1,1} = nasa_toLustre.lustreAst.LustreVar(v_name, v_type);
            else
                %UNKNOWN Variable
                display_msg(sprintf('Variable %s in Chart %s not found',...
                    v_name, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
            end
        end
    end
    %Node Call
    node_call = nasa_toLustre.lustreAst.NodeCallExpr(node_call.getNodeName(), nodeCall_inputs_Ids);
    body{end+1} = nasa_toLustre.lustreAst.LustreEq(nodeCall_outputs_Ids, node_call);

    % set unused outputs to their initial values or zero
    body{end+1} = nasa_toLustre.lustreAst.LustreComment('Set unused outputs');
    for i=1:numel(outputsData)
        d = outputsData{i};
        d_names = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataName(d);
        for j=1:numel(d_names)
            d_name = d_names{j};
            if ismember(d_name, nodeCall_outputs_Names)
                % it's used
                continue;
            end
            [v, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
            if status
                display_msg(...
                    sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                    d.InitialValue, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
                v = 0;
            end
            if numel(v) >= j
                v = v(j);
            else
                v = v(1);
            end
            IC_Var =nasa_toLustre.utils.SLX2LusUtils.num2LusExp(v, d.LusDatatype);
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(d_name), IC_Var);
        end
    end

end

