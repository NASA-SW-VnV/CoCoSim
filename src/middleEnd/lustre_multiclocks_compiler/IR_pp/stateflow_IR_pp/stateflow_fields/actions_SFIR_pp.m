function [ new_ir, status ] = actions_SFIR_pp( new_ir )
%actions_SFIR_pp adapt Stateflow actions to lustre syntax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
states_fields = {'Entry', 'During', 'Exit', 'Bind', 'On', 'OnAfter', ...
    'OnBefore', 'OnAt', 'OnEvery'};
for i=1:numel(new_ir.States)
    %State Actions
    for f=states_fields
        if isfield(new_ir.States{i}.Actions, f)
            [new_ir.States{i}.Actions.(f{1}), status] = ...
                adapt_actions(new_ir.States{i}.Actions.(f{1}), new_ir.Data);
            if status
                display_msg(['ERROR found in state:' new_ir.States{i}.Path], ...
                    MsgType.ERROR, 'actions_SFIR_pp', '');
                return;
            end
        end
    end
    % default transition
    [new_ir.States{i}.Composition.DefaultTransitions, status] = ...
        adapt_transitions(new_ir.States{i}.Composition.DefaultTransitions, new_ir.Data);
    if status
        display_msg(['ERROR found in state:' new_ir.States{i}.Path], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    end
    %OuterTransitions
    [new_ir.States{i}.OuterTransitions, status] = ...
        adapt_transitions(new_ir.States{i}.OuterTransitions, new_ir.Data);
    if status
        display_msg(['ERROR found in state:' new_ir.States{i}.Path], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    end
    %InnerTransitions
    [new_ir.States{i}.InnerTransitions, status] = ...
        adapt_transitions(new_ir.States{i}.InnerTransitions, new_ir.Data);
    if status
        display_msg(['ERROR found in state:' new_ir.States{i}.Path], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    end
end


for i=1:numel(new_ir.Junctions)
    [new_ir.Junctions{i}.OuterTransitions, status] = ...
        adapt_transitions(new_ir.Junctions{i}.OuterTransitions, new_ir.Data);
    if status
        display_msg(['ERROR found in Junction:' new_ir.Junctions{i}.Path], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    end
end

for i=1:numel(new_ir.GraphicalFunctions)
    [new_ir.GraphicalFunctions{i}, status] = actions_SFIR_pp( new_ir.GraphicalFunctions{i} );
    if status
        display_msg(['ERROR found in StateflowFunction:' new_ir.GraphicalFunctions{i}.origin_path], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    end
end

end

%%
function [transitions, status] = adapt_transitions(transitions, data)
status = 0;
for i=1:numel(transitions)
    [transitions{i}.Condition, status] = adapt_actions({transitions{i}.Condition}, data, 1);
    if status
        return;
    end
    [transitions{i}.ConditionAction, status] = adapt_actions(transitions{i}.ConditionAction, data);
    if status
        return;
    end
    [transitions{i}.TransitionAction, status] = adapt_actions(transitions{i}.TransitionAction, data);
    if status
        return;
    end
end
end
%%

function [res, status] = adapt_actions(actions, data, isCondition)
if nargin < 3
    isCondition = false;
end
try
    [res, status] = adapt_actions_using_java_parser(actions, data, isCondition);
catch ME
    display_msg('Java parser has failed, Matlab parser will be used', ...
        MsgType.ERROR, 'actions_SFIR_pp', '');
    display_msg(ME.getReport(), ...
        MsgType.DEBUG, 'actions_SFIR_pp', '');
    status = 1;
end
if status
    [res, status] = adapt_actions_using_Matlab_parser(actions, data, isCondition);
end

end
%%
function [res, status] = adapt_actions_using_Matlab_parser(actions, data, isCondition)
status = 0;
if nargin < 3
    isCondition = false;
end
new_actions = actions;
external_nodes = [];
node_struct.inputs = {};
node_struct.outputs = {};

res.actions = '';
res.inputs = '';
res.outputs = '';
res.external_fun = '';
if isempty(actions)
    return;
end
if ~iscell(actions)
    % adaptation from old IR to new IR
    actions{1} = SFIRUtils.split_actions(actions);
end
for i=1:numel(actions)
    [new_actions{i}, data, node_struct, external_nodes_i] = ...
        SFIRPPUtils.adapt_action(actions{i}, data, node_struct, isCondition);
    external_nodes = [external_nodes, external_nodes_i];
end

inputs_data = MatlabUtils.structUnique(node_struct.inputs, 'Name');
outputs_data = node_struct.outputs;
inputs = {};
for i=1:numel(inputs_data)
    inputs{i} = sprintf('%s: %s;',...
        inputs_data{i}.Name, SFIRPPUtils.to_lustre_dt(inputs_data{i}.Datatype));
end
outputs = {};
for i=1:numel(outputs_data)
    if isfield(outputs_data{i}, 'index') && ~isempty(outputs_data{i}.index)
        name = sprintf('%s__%d', outputs_data{i}.Name, outputs_data{i}.index);
    else
        name = outputs_data{i}.Name;
    end
    outputs{i} = sprintf('%s: %s;',...
        name, SFIRPPUtils.to_lustre_dt(outputs_data{i}.Datatype));
end
res.actions = MatlabUtils.strjoin(new_actions, ' ');
res.inputs = MatlabUtils.strjoin(inputs,  '');
res.outputs = MatlabUtils.strjoin(outputs,  '');
if ~isempty(external_nodes)
    res.external_fun = MatlabUtils.strjoin({external_nodes.Name}, ', ');
else
    res.external_fun = '';
end
end

%%
function [res, status] = adapt_actions_using_java_parser(actions, data, isCondition)
if nargin < 3
    isCondition = false;
end
if ~iscell(actions) && ~isempty(actions)
    % adaptation from old IR to new IR
    actions{1} = actions;
end
status = 0;
if(~isempty(actions))
    res.actions = actions;
    res.original_actions = MatlabUtils.strjoin(actions, '; ');
else
    res.original_actions = '';
    res.actions = '';
end
res.inputs = '';
res.outputs = '';
res.external_fun = '';
res.variables = '';

if ~isempty(actions)
    [ actions_struct] = SFIRPPUtils.extractInputsOutputs(actions, data, isCondition);
    inputs_data = MatlabUtils.structUnique(actions_struct.inputs, 'Name');
    
    outputs_data = MatlabUtils.structUnique(actions_struct.outputs, 'Name');
    
    inputs_names = {};
    declare_type = {};
    for i=1:numel(inputs_data)
        inputs_names{i} = inputs_data{i}.Name;
        declare_type{i} = sprintf('%%@DeclareType %s: %s;\n',...
            inputs_data{i}.Name, SFIRPPUtils.to_lustre_dt(inputs_data{i}.Datatype));
    end
    outputs_names = {};
    for i=1:numel(outputs_data)
        outputs_names{i} = outputs_data{i}.Name;
        if ~ismember(outputs_names{i}, inputs_names)
            declare_type{numel(declare_type) + 1} = sprintf('\%@DeclareType %s: %s;\n',...
                outputs_data{i}.Name, SFIRPPUtils.to_lustre_dt(outputs_data{i}.Datatype));
        end
    end
    buf = java.lang.StringBuilder();
    buf.append('function [');
    if (~isempty(outputs_names))
        buf.append(MatlabUtils.strjoin(outputs_names, ', '));
    end
    buf.append('] = fun(');
    if (~isempty(inputs_names))
        buf.append(MatlabUtils.strjoin(inputs_names, ', '));
    end
    buf.append(sprintf(')\n'));
    buf.append(MatlabUtils.strjoin(declare_type, ''));
    buf.append(MatlabUtils.strjoin(actions, '\n'));
    buf.append(sprintf('\nend'));
    
    try
        em2lustre =  cocosim.matlab2Lustre.EM2PseudoLustre;
        converter = em2lustre.StringToLustre(buf.toString());
    catch ME
        display_msg(char(buf.toString()), ...
            MsgType.DEBUG, 'actions_SFIR_pp', '');
        display_msg(ME.getReport(),  MsgType.DEBUG, 'actions_SFIR_pp', '');
        status = 1;
        return;
    end
    unsupported_exp = char(converter.getUnsupported_exp());
    if ~isempty(unsupported_exp)
        status = 1;
        display_msg(['The following actions are not supported :' unsupported_exp], ...
            MsgType.ERROR, 'actions_SFIR_pp', '');
        return;
    else
        res.inputs = char(converter.getInputsStr());
        res.inputs = regexprep(res.inputs, '\s*\n+', '');
        res.outputs = char(converter.getOutputsStr());
        res.outputs = regexprep(res.outputs, '\s*\n+', '');
        res.variables = char(converter.getVariablesStr());
        res.variables = regexprep(res.variables, '\s*\n+', '');
        if isCondition
            res.actions = char(converter.getLus_body().replaceAll( ';', ''));
        else
            res.actions = char(converter.getLus_body());
        end
        res.actions = regexprep(res.actions, '\n', ' ');
        res.external_fun = char(converter.getExternal_fun_str());
    end
end
end

%%
