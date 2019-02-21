
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% chart body
function [outputs, inputs, variables, body] = write_chart_body(...
        parent, blk, chart, dataAndEvents, inputEvents)
    global SF_STATES_NODESAST_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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
        if isequal(d.Scope, 'Input')
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
                Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
            if status
                display_msg(sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                    d.InitialValue, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
                v = 0;
            end
            if isequal(d.Scope, 'Parameter')
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

            if ~isequal(d.Scope, 'Output')
                variables{end+1} = LustreVar(d_name, d.LusDatatype);
            end
            if isequal(d.Scope, 'Output')
                d_firstName = strcat(d_name, '__1');
                if ismember(d_name, nodeCall_inputs_Names)
                    body{end+1} = LustreEq(...
                        VarIdExpr(d_firstName), ...
                        BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                        UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_name))));
                    variables{end+1} = LustreVar(d_firstName, d.LusDatatype);
                    nodeCall_inputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_inputs_Ids, d_name, d_firstName);
                end
            elseif isequal(d.Scope, 'Local')
                d_lastName = strcat(d_name, '__2');
                if ismember(d_name, nodeCall_outputs_Names)
                    body{end+1} = LustreEq(...
                        VarIdExpr(d_name), ...
                        BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                        UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_lastName))));
                    variables{end+1} = LustreVar(d_lastName, d.LusDatatype);
                    nodeCall_outputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_outputs_Ids, d_name, d_lastName);
                else
                    %local variable that was not modified in the chart
                    body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
                end
            elseif isequal(d.Scope, 'Constant')
                body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
            elseif isequal(d.Scope, 'Parameter')
                body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
            end
        end
    end

    %state IDs
    allVars = MatlabUtils.concat(variables, outputs, inputs);
    nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
        nodeCall_inputs_Ids, 'UniformOutput', false);
    for i=1:numel(nodeCall_inputs_Names)
        v_name = nodeCall_inputs_Names{i};
        if ~VarIdExpr.ismemberVar(v_name, allVars)
            if MatlabUtils.endsWith(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix())
                %State ID
                v_type = strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateEnumSuffix());
                v_inactive = VarIdExpr(upper(...
                    strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    '_INACTIVE')));
                variables{end+1} = LustreVar(v_name, v_type);
                if ismember(v_name, nodeCall_outputs_Names)
                    v_lastName = strcat(v_name, '__2');
                    body{end+1} = LustreEq(...
                        VarIdExpr(v_name), ...
                        BinaryExpr(BinaryExpr.ARROW, v_inactive, ...
                        UnaryExpr(UnaryExpr.PRE, VarIdExpr(v_lastName))));
                    variables{end+1} = LustreVar(v_lastName, v_type);
                    nodeCall_outputs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        nodeCall_outputs_Ids, v_name, v_lastName);
                else
                    body{end+1} = LustreEq(VarIdExpr(v_name), v_inactive);
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
    allVars = MatlabUtils.concat(variables, outputs, inputs);
    for i=1:numel(nodeCall_outputs_Names)
        v_name = nodeCall_outputs_Names{i};
        if ~VarIdExpr.ismemberVar(v_name, allVars)
            if MatlabUtils.endsWith(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix())
                v_type = strrep(v_name, ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix(), ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateEnumSuffix());
                variables{end+1,1} = LustreVar(v_name, v_type);
            else
                %UNKNOWN Variable
                display_msg(sprintf('Variable %s in Chart %s not found',...
                    v_name, chart.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
            end
        end
    end
    %Node Call
    node_call = NodeCallExpr(node_call.getNodeName(), nodeCall_inputs_Ids);
    body{end+1} = LustreEq(nodeCall_outputs_Ids, node_call);

    % set unused outputs to their initial values or zero
    body{end+1} = LustreComment('Set unused outputs');
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
                Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
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
            body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
        end
    end

end

