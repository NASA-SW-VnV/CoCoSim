function program =  stateflow_IR( chart_path , output_dir, print_in_file)
%STATEFLOW_IR generatesan internal representation for a Stateflow chart

if nargin ==0 || isempty(chart_path)
    display_msg('please provide Stateflow chart path while calling stateflow_IR',...
        MsgType.ERROR, 'stateflow_IR', '');
    return;
end
if nargin < 2 || isempty(output_dir)
    output_dir = pwd;
end
if nargin < 3 || isempty(print_in_file)
    print_in_file = 0;
end

%% extract chart
paths = regexp(chart_path, '/', 'split');
file_name = paths{1};
rt = sfroot;
m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',file_name);
chart = m.find('-isa','Stateflow.Chart', 'Path', char(chart_path));
if isempty(chart)
    program = [];
    display_msg(sprintf('Stateflow chart path %s is unknown', chart_path),...
        MsgType.ERROR, 'stateflow_IR', '');
    return;
end


[src_states, src_junctions, src_fcts, data] = get_chart_objects(chart, 0);

program = Program(chart_path, src_states, src_junctions, src_fcts, data, 0);

if print_in_file
    json_text = json_encode(program);
    json_text = regexprep(json_text, '\\/','/');
    fname = fullfile(output_dir, strcat(file_name,'_tmp.json'));
    fname_formatted = fullfile(output_dir, strcat(file_name,'.json'));
    fid = fopen(fname, 'w');
    if fid==-1
        display_msg(['Couldn''t create file ' fname], MsgType.ERROR, 'Stateflow_IRPP', '');
    else
        fprintf(fid,'%s\n',json_text);
        fclose(fid);
        cmd = ['cat ' fname ' | python -mjson.tool > ' fname_formatted];
        try
            [status, output] = system(cmd);
            if status~=0
                display_msg(['file is not formatted ' output], MsgType.ERROR, 'Stateflow_IRPP', '');
                fname_formatted = fname;
            end
        catch
            fname_formatted = fname;
        end
    end
    display_msg(['IR has been written in ' fname_formatted], MsgType.RESULT, 'Stateflow_IRPP', '');
end
end


%%
function [src_states, src_junctions, src_fcts, data_def] = get_chart_objects(chart, isFunction)
%% states
states = Program.get_all_states(chart);
src_states = [];
for s=states'
    s_obj = State_def.create_object(chart, s);
    src_states = [src_states; s_obj];
end
% if ~isFunction
    state_actions.entry = '';
    state_actions.during = '';
    state_actions.exit = '';
    fullpath = chart.Path;
    comp = Composition.create_object(chart, isFunction);
    s_obj = State_def(fullpath, state_actions, [], [], comp);
    src_states = [s_obj; src_states];
% end
%% junctions
junctions = chart.find('-isa','Stateflow.Junction');
src_junctions = [];
for j=junctions'
    j_obj = Junction.create_object(chart, j);
    src_junctions = [src_junctions; j_obj];
end

%% stateflow functions
functions = chart.find('-isa','Stateflow.Function');
if isFunction && numel(functions)>1
    functions = functions(2:end);
elseif (isFunction && numel(functions) == 1) || numel(functions)==0
    functions = [];
end
src_fcts = [];
data_fcts = [];
for i=1:numel(functions)
    f = functions(i);
    [S, J, F, D] = get_chart_objects(f, 1);
    f_path = fullfile(f.Path, f.Name);
    f_obj = Program(f_path, S, J, F, D, 1);
    src_fcts = [src_fcts; f_obj];
    data_fcts = [data_fcts; D];
end

%% data
data = chart.find('-isa', 'Stateflow.Data', '-depth', 1);
events = chart.find('-isa', 'Stateflow.Event', '-depth', 1);
data_def = [];
for i=1:numel(data)
    d = data(i);
    d_obj = Data.create_object(d);
    data_def = [data_def; d_obj];
end
for i=1:numel(events)
    e = events(i);
    e_obj = Data.create_object(e, 1);
    data_def = [data_def; e_obj];
end

end