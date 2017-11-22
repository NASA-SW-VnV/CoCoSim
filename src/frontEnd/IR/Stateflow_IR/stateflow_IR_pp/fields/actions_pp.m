function [ new_ir ] = actions_pp( new_ir )
%ACTIONS_PP adapt Stateflow actions to lustre syntax

for i=1:numel(new_ir.states)
    new_ir.states(i).state_actions.entry = adapt_actions(new_ir.states(i).state_actions.entry, new_ir.data);
    new_ir.states(i).state_actions.during = adapt_actions(new_ir.states(i).state_actions.during, new_ir.data);
    new_ir.states(i).state_actions.exit = adapt_actions(new_ir.states(i).state_actions.exit, new_ir.data);
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
    transitions(i).condition_act = adapt_actions(transitions(i).condition_act, data);
    transitions(i).transition_act = adapt_actions(transitions(i).transition_act, data);
end
end
%%
function new_actions = adapt_actions(actions, data)
new_actions = actions;
if strcmp(actions, '')
    return;
end
for i=1:numel(actions)
    
    new_actions{i} = adapt_action(actions{i}, data);
%     if ~strcmp(new_actions{i}, actions{i})
%     fprintf('old : %s\n', actions{i});
%     fprintf('new : %s\n', new_actions{i});
%     end
end
end

%%
function [action_updated] = adapt_action(action, data)
expression = '(\s|;|\])';
replace = '';
action_updated = regexprep(action,expression,replace);
%for arrays x[1][3] -> x_1_3
expression = '(\w)+(\[)';
replace = '$1_';
action_updated = regexprep(action_updated,expression,replace);
expression = '\[';
replace = '';
action_updated = regexprep(action_updated,expression,replace);
expression = '/\*(\s*\w*\W*\s*)*\*/';
replace = '';
action_updated = regexprep(action_updated,expression,replace);
expression = '(+{2}|-{2}|[+\-*/]=|={1})';
[operands, tokens] = regexp(action_updated,expression,'split','tokens');
left_operand =operands{1};
if numel(operands) >1
    right_operand = operands{2};
    token = tokens{1};
else
    right_operand = '';
    token = '';
end

expression = '(=|+{2}|\-{2})';
[operands, ind] = regexp(action_updated,expression,'split','end');
switch char(token)
    case '+='
        right_expression = [left_operand ' + ' right_operand];
        action_updated = [left_operand, ' = ' right_expression];
    case '-='
        right_expression = [left_operand ' - ' right_operand];
        action_updated = [left_operand, ' = ' right_expression];
    case '*='
        right_expression = [left_operand ' * ' right_operand];
        action_updated = [left_operand, ' = ' right_expression];
    case '/='
        right_expression = [left_operand ' / ' right_operand];
        action_updated = [left_operand, ' = ' right_expression];
    otherwise
        right_expression = '';
        if contains(action_updated,'++')
            right_expression = strcat(operands{1},' + 1');
        elseif contains(action_updated,'--')
            right_expression = strcat(operands{1},' - 1');
        else
            if ~isempty(ind) && numel(action_updated)>=ind(1)+1
                right_expression =action_updated(ind(1)+1:end);
                if contains(right_expression,'==')
                    expression = '={2}';
                    replace = '=';
                    right_expression = regexprep(right_expression,expression,replace);
                end
            else
                right_expression = action_updated;
            end
            
        end
        
end
if isempty(data)
    return;
end
d = data(strcmp({data.name},left_operand));
data_notfound = 0;
if isempty(d)
    if contains(action, '[')
        vec = regexp(action,'\[','split');
        d = data(strcmp({data.name},vec{1}));
        if isempty(d)
            data_notfound = 1;
        end
    else
        data_notfound = 1;
    end
end

if data_notfound
    return;
end

datatype = d.datatype;
if strcmp(SFIRUtils.to_lustre_dt(datatype),'real') 
    if contains(action_updated,'++') || contains(action_updated,'--') || isempty(strfind(operands{2},'.'))
        expression = '(\<|[=+{2}\-{2}]\s*)(\d+)';
        replace = '$1$2.0';
        right_expression =  regexprep(right_expression,expression,replace);
    end
elseif strcmp(SFIRUtils.to_lustre_dt(datatype),'bool')
    expression = '(\<|[=+{2}\-{2}]\s*)(1)';
    replace = '$1true';
    right_expression =  regexprep(right_expression,expression,replace);
    expression = '(\<|[=+{2}\-{2}]\s*)(0)';
    replace = '$1false';
    right_expression =  regexprep(right_expression,expression,replace);
end


action_updated = [left_operand, '=' right_expression];
end