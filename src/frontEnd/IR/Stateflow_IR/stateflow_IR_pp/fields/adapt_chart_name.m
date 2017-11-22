function new_ir = adapt_chart_name(new_ir, isSF)
%adapt_chart_name change the chart path to one name to be adapted to lustre
%compiler that only accept chart name to be the root name of all paths.
%file_name/subsystem_A/chart1 -> file_name_subsystem_A_chart1
if nargin < 2
    isSF = 0;
end
if isSF
    new_name = regexp(new_ir.name, filesep, 'split');
    new_name = new_name{end};
else
    new_name = SFIRUtils.adapt_root_name(new_ir.name);
end
origin_name_pattern = strcat('^', new_ir.name);

new_ir.states = adapt_states_name(new_ir.states, origin_name_pattern, new_name);

new_ir.junctions = adapt_junctions_name(new_ir.junctions, origin_name_pattern, new_name);

new_ir.name = new_name;

for i=1:numel(new_ir.sffunctions)
    new_ir.sffunctions(i) = adapt_chart_name( new_ir.sffunctions(i), 1 );
end
end

%% adapt root name
function states = adapt_states_name(states, origin_name_pattern, new_name)
for i=1:numel(states)
    states(i).path = regexprep(states(i).path, origin_name_pattern, new_name);
    
    states(i).outer_trans = adapt_transitions_name(...
        states(i).outer_trans, origin_name_pattern, new_name);
    
    states(i).inner_trans = adapt_transitions_name(...
        states(i).inner_trans, origin_name_pattern, new_name);
    
    states(i).internal_composition = adapt_composition_name(...
        states(i).internal_composition, origin_name_pattern, new_name);
    
end
end

%% adapt junctions root name
function junctions = adapt_junctions_name(junctions, origin_name_pattern, new_name)
for i=1:numel(junctions)
    junctions(i).path = regexprep(junctions(i).path, origin_name_pattern, new_name);
    
    junctions(i).outer_trans = adapt_transitions_name(...
        junctions(i).outer_trans, origin_name_pattern, new_name);
    
end
end

%% adapt root name for transitions
function trans = adapt_transitions_name(trans, origin_name_pattern, new_name)
for j=1:numel(trans)
    trans(j).dest.name =  ...
        regexprep(...
        trans(j).dest.name,...
        origin_name_pattern, new_name);
    
end
end
%% adapt root name for internal composition

function internal_composition = adapt_composition_name(...
    internal_composition, origin_name_pattern, new_name)

internal_composition.tinit = adapt_transitions_name(...
    internal_composition.tinit, origin_name_pattern, new_name);
end