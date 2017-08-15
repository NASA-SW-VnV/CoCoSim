function program =  stateflow_IR( chart_path , output_dir, print_in_file)
%STATEFLOW_IR generatesan internal representation for a Stateflow chart

if nargin ==0 || isempty(chart_path)
    display_msg('please provide Stateflow chart path while calling stateflow_IR',...
        Constants.ERROR, 'stateflow_IR', '');
end
if nargin < 2 || isempty(output_dir)
    output_dir = pwd;
end
if nargin < 3 || isempty(print_in_file)
    print_in_file = 0;
end

paths = regexp(chart_path, '/', 'split');
chart_name = paths{1};
rt = sfroot;
m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',chart_name);
chart = m.find('-isa','Stateflow.Chart', 'Path', char(chart_path));
states = Program.get_all_states(chart);
src_states = [];
for s=states'
    s_obj = State_def.create_object(chart, s);
    src_states = [src_states; s_obj];
end

junctions = chart.find('-isa','Stateflow.Junction');
src_junctions = [];
for j=junctions'
    j_obj = Junction.create_object(chart, j);
    src_junctions = [src_junctions; j_obj];
end

program = Program(chart_name, src_states, src_junctions);

if print_in_file
    json_text = jsonencode(program);
    json_text = regexprep(json_text, '\\/','/');
    fid = fopen(fullfile(output_dir, strcat(chart_name,'.json')), 'w');
    fprintf(fid,'%s\n',json_text);
    fclose(fid);
end
end

