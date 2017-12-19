function [ new_ir, status ] = actions_pp( new_ir )
%ACTIONS_PP adapt Stateflow actions to lustre syntax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
for i=1:numel(new_ir.states)
    [new_ir.states(i).state_actions.entry_act, status] = adapt_actions(new_ir.states(i).state_actions.entry_act, new_ir.data);
    if status
        display_msg(['ERROR found in state:' new_ir.states(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
    [new_ir.states(i).state_actions.during_act, status] = adapt_actions(new_ir.states(i).state_actions.during_act, new_ir.data);
    if status
        display_msg(['ERROR found in state:' new_ir.states(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
    [new_ir.states(i).state_actions.exit_act, status] = adapt_actions(new_ir.states(i).state_actions.exit_act, new_ir.data);
    if status
        display_msg(['ERROR found in state:' new_ir.states(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
    [new_ir.states(i).outer_trans, status] = adapt_transitions(new_ir.states(i).outer_trans, new_ir.data);
    if status
        display_msg(['ERROR found in state:' new_ir.states(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
    [new_ir.states(i).inner_trans, status] = adapt_transitions(new_ir.states(i).inner_trans, new_ir.data);
    if status
        display_msg(['ERROR found in state:' new_ir.states(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
end


for i=1:numel(new_ir.junctions)
    [new_ir.junctions(i).outer_trans, status] = adapt_transitions(new_ir.junctions(i).outer_trans, new_ir.data);
    if status
        display_msg(['ERROR found in Junction:' new_ir.junctions(i).path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
end

for i=1:numel(new_ir.sffunctions)
    [new_ir.sffunctions(i), status] = actions_pp( new_ir.sffunctions(i) );
    if status
        display_msg(['ERROR found in StateflowFunction:' new_ir.sffunctions(i).origin_path], ...
            MsgType.ERROR, 'actions_pp', '');
        return;
    end
end

end

%%
function [transitions, status] = adapt_transitions(transitions, data)
status = 0;
for i=1:numel(transitions)
    [transitions(i).condition, status] = adapt_actions({transitions(i).condition}, data, 1);
    if status
        return;
    end
    [transitions(i).condition_act, status] = adapt_actions(transitions(i).condition_act, data);
    if status
        return;
    end
    [transitions(i).transition_act, status] = adapt_actions(transitions(i).transition_act, data);
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
        MsgType.ERROR, 'actions_pp', '');
    display_msg(ME.getReport(), ...
        MsgType.DEBUG, 'actions_pp', '');
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
if strcmp(actions, '')
    return;
end

for i=1:numel(actions)
    [new_actions{i}, data, node_struct, external_nodes_i] = SFIRPPUtils.adapt_action(actions{i}, data, node_struct, isCondition);
    external_nodes = [external_nodes, external_nodes_i];
end
inputs_data = MatlabUtils.structUnique(node_struct.inputs, 'name');
outputs_data = node_struct.outputs;
inputs = {};
for i=1:numel(inputs_data)
    inputs{i} = sprintf('%s: %s;',...
        inputs_data{i}.name, SFIRPPUtils.to_lustre_dt(inputs_data{i}.datatype));
end
outputs = {};
for i=1:numel(outputs_data)
    if isfield(outputs_data{i}, 'index') && ~isempty(outputs_data{i}.index)
        name = sprintf('%s__%d', outputs_data{i}.name, outputs_data{i}.index);
    else
        name = outputs_data{i}.name;
    end
    outputs{i} = sprintf('%s: %s;',...
        name, SFIRPPUtils.to_lustre_dt(outputs_data{i}.datatype));
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
status = 0;
res.actions = actions;
res.inputs = '';
res.outputs = '';
res.external_fun = '';
res.variables = '';
if ~isempty(actions)
    [ actions_struct] = SFIRPPUtils.extractInputsOutputs(actions, data, isCondition);
    inputs_data = MatlabUtils.structUnique(actions_struct.inputs, 'name');
    
    outputs_data = MatlabUtils.structUnique(actions_struct.outputs, 'name');
    
    inputs_names = {};
    declare_type = {};
    for i=1:numel(inputs_data)
        inputs_names{i} = inputs_data{i}.name;
        declare_type{i} = sprintf('%%@DeclareType %s: %s;\n',...
            inputs_data{i}.name, SFIRPPUtils.to_lustre_dt(inputs_data{i}.datatype));
    end
    outputs_names = {};
    for i=1:numel(outputs_data)
        outputs_names{i} = outputs_data{i}.name;
        if ~ismember(outputs_names{i}, inputs_names)
            declare_type{numel(declare_type) + 1} = sprintf('\%@DeclareType %s: %s;\n',...
                outputs_data{i}.name, SFIRPPUtils.to_lustre_dt(outputs_data{i}.datatype));
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
    em2lustre =  cocosim.matlab2Lustre.EM2Lustre;
    converter = em2lustre.StringToLustre(buf.toString());
    catch ME
        display_msg('Error using cocosim.matlab2Lustre.EM2Lustre', ...
            MsgType.ERROR, 'actions_pp', '');
        display_msg(ME.getReport(),  MsgType.DEBUG, 'actions_pp', '');
        status = 1;
        return;
    end
    unsupported_exp = char(converter.getUnsupported_exp());
    if ~isempty(unsupported_exp)
        status = 1;
        display_msg(['The following actions are not supported :' unsupported_exp], ...
            MsgType.ERROR, 'actions_pp', '');
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
