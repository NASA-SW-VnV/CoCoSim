function [new_ir, status] = chart_name_SFIR_pp(new_ir, isSF)
%chart_name_SFIR_pp change the chart path to one name to be adapted to lustre
%compiler that only accept chart name to be the root name of all paths.
%file_name/subsystem_A/chart1 -> file_name_subsystem_A_chart1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
if nargin < 2
    isSF = 0;
end
if isSF
    new_name = regexp(new_ir.Path, filesep, 'split');
    new_name = new_name{end};
else
    new_name = SFIRPPUtils.adapt_root_name(new_ir.Path);
end
origin_name_pattern = strcat('^', new_ir.Path);

new_ir.States = adapt_states_name(new_ir.States, origin_name_pattern, new_name);

new_ir.Junctions = adapt_junctions_name(new_ir.Junctions, origin_name_pattern, new_name);

new_ir.Path = new_name;

for i=1:numel(new_ir.GraphicalFunctions)
    new_ir.GraphicalFunctions{i} = chart_name_SFIR_pp( new_ir.GraphicalFunctions{i}, 1 );
end
end

%% adapt root name
function states = adapt_states_name(states, origin_name_pattern, new_name)
for i=1:numel(states)
    states{i}.Path = regexprep(states{i}.Path, origin_name_pattern, new_name);
    
    states{i}.OuterTransitions = adapt_transitions_name(...
        states{i}.OuterTransitions, origin_name_pattern, new_name);
    
    states{i}.InnerTransitions = adapt_transitions_name(...
        states{i}.InnerTransitions, origin_name_pattern, new_name);
    
    states{i}.Composition = adapt_composition_name(...
        states{i}.Composition, origin_name_pattern, new_name);
    
end
end

%% adapt junctions root name
function junctions = adapt_junctions_name(junctions, origin_name_pattern, new_name)
for i=1:numel(junctions)
    junctions{i}.Path = regexprep(junctions{i}.Path, origin_name_pattern, new_name);
    
    junctions{i}.OuterTransitions = adapt_transitions_name(...
        junctions{i}.OuterTransitions, origin_name_pattern, new_name);
    
end
end

%% adapt root name for transitions
function trans = adapt_transitions_name(trans, origin_name_pattern, new_name)
for j=1:numel(trans)
    trans{j}.Destination.Name =  ...
        regexprep(...
        trans{j}.Destination.Name,...
        origin_name_pattern, new_name);
    
end
end
%% adapt root name for internal composition

function internal_composition = adapt_composition_name(...
    internal_composition, origin_name_pattern, new_name)

internal_composition.DefaultTransitions = adapt_transitions_name(...
    internal_composition.DefaultTransitions, origin_name_pattern, new_name);
end