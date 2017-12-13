function [ new_ir ] = actions_pp( new_ir )
%ACTIONS_PP adapt Stateflow actions to lustre syntax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:numel(new_ir.states)
    new_ir.states(i).state_actions.entry_act = adapt_actions(new_ir.states(i).state_actions.entry_act, new_ir.data);
    new_ir.states(i).state_actions.during_act = adapt_actions(new_ir.states(i).state_actions.during_act, new_ir.data);
    new_ir.states(i).state_actions.exit_act = adapt_actions(new_ir.states(i).state_actions.exit_act, new_ir.data);
    new_ir.states(i).outer_trans = adapt_transitions(new_ir.states(i).outer_trans, new_ir.data);
    new_ir.states(i).inner_trans = adapt_transitions(new_ir.states(i).inner_trans, new_ir.data);
end


for i=1:numel(new_ir.junctions)
    new_ir.junctions(i).outer_trans = adapt_transitions(new_ir.junctions(i).outer_trans, new_ir.data);
end

for i=1:numel(new_ir.sffunctions)
    new_ir.sffunctions(i) = actions_pp( new_ir.sffunctions(i) );
end

end

%%
function transitions = adapt_transitions(transitions, data)
for i=1:numel(transitions)
    transitions(i).condition = adapt_actions({transitions(i).condition}, data, 1);
    transitions(i).condition_act = adapt_actions(transitions(i).condition_act, data);
    transitions(i).transition_act = adapt_actions(transitions(i).transition_act, data);
end
end
%%
function res = adapt_actions(actions, data, isCondition)
if nargin < 3
    isCondition = false;
end
new_actions = actions;
external_nodes = [];
node_struct.intputs = {};
node_struct.outputs = {};
% initialize output
res.actions = new_actions;
res.node_struct = node_struct;
res.external_nodes = external_nodes;

if strcmp(actions, '')
    return;
end

for i=1:numel(actions)
    [new_actions{i}, data, node_struct, external_nodes_i] = SFIRPPUtils.adapt_action(actions{i}, data, node_struct, isCondition);
    external_nodes = [external_nodes, external_nodes_i];
end
res.actions = new_actions;
res.action_struct.intputs = MatlabUtils.structUnique(node_struct.intputs, 'name');
res.action_struct.outputs = node_struct.outputs;
res.external_nodes = external_nodes;
end

%%
