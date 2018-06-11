function pp_user_config(fcts_map, ordered_functions)
%PP_USER_CONFIG  This is a configuration window enable the user to change
%the default configuration defined in pp_config.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global ordered_pp_functions priority_pp_map;
if isempty(ordered_pp_functions)
    pp_config;
end
if nargin < 2
    fcts_map = priority_pp_map;
    ordered_functions = ordered_pp_functions;
end
cocoSim_path = fileparts(which('start_cocosim'));
css_source = fullfile(cocoSim_path, 'libs', 'materialize' , 'css' , 'materialize.css');
html_text = fileread(fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'pp_config.html'));
html_text = strrep(html_text, '[css_source]', css_source);

%add libraries names
libraries_path = unique(cellfun(@fileparts, ordered_functions, 'UniformOutput', false));
library_item = '<a class="collection-item"><div class="blue-text text-darken-2">[Item]</div></a>';
List_Libraries = '';
for i=1:numel(libraries_path)
    code = strrep(library_item, '[Item]', libraries_path{i});
    List_Libraries = [List_Libraries, '\n', code];
end
html_text = strrep(html_text, '[List_Libraries]', List_Libraries);

% add function names and code
function_item = '<tr> <td>[NAME]</td>  <td><input type="text" id="fcn[ID]" value="[VALUE]"></td> <td>[HELP]</td> </tr>';
% code_item = '"''" + document.form.fcn[ID].value + "''"';
code_item = 'document.getElementById(''fcn[ID]'').value';

List_Functions = '';
keySet_items = {};
valueSet_items = {};
fcn_idx = 1;
%start by priority -1
for k= fcts_map.keys
    priority = fcts_map(k{1});
    if priority == -1
        [~, name, ~] = fileparts(k{1});
        help_msg = divide_msg(evalc(['help ' k{1}]), 60);
        line = strrep(function_item, '[NAME]', name);
        line = strrep(line, '[HELP]', help_msg);
        line = strrep(line, '[ID]', num2str(fcn_idx));
        line = strrep(line, '[VALUE]', num2str(priority));
        
        List_Functions = [List_Functions, '\n', line];
        keySet_items{numel(keySet_items) + 1} =strcat('''', k{1}, '''');
        valueSet_items{numel(valueSet_items) + 1} = strrep(code_item, '[ID]', num2str(fcn_idx));
        fcn_idx = fcn_idx + 1;
    end
end
% list functions by their priority order
for i=1:numel(ordered_functions)
    priority = fcts_map(ordered_functions{i});
    [~, name, ~] = fileparts(ordered_functions{i});
    help_msg = divide_msg(evalc(['help ' ordered_functions{i}]), 60);
    line = strrep(function_item, '[NAME]', name);
    line = strrep(line, '[ID]', num2str(fcn_idx));
    line = strrep(line, '[VALUE]', num2str(priority));
    line = strrep(line, '[HELP]', help_msg);
    List_Functions = [List_Functions, '\n', line];
    keySet_items{numel(keySet_items) + 1} = strcat('''', ordered_functions{i}, '''');
    valueSet_items{numel(valueSet_items) + 1} = strrep(code_item, '[ID]', num2str(fcn_idx));
    fcn_idx = fcn_idx + 1;
end

html_text = strrep(html_text, '[keySet]', strjoin(keySet_items, ','));
html_text = strrep(html_text, '[valueSet]', strjoin(valueSet_items, '+","+'));
html_text = strrep(html_text, '[List_Functions]', List_Functions);



tmp_dir  = fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'tmp');
html_path = fullfile(tmp_dir, 'pp_config_local.html');
if ~exist(tmp_dir, 'dir')
    mkdir(tmp_dir);
end
fid = fopen(html_path, 'w+');

if ~strcmp(html_text, '')
    html_text = regexprep(html_text, '%+', '');
    fprintf(fid, html_text);
    open(html_path);
end
end

%%
function msg = divide_msg(original_msg, n)
% divide msg on many lines
% remove licence
original_msg = regexprep(original_msg, '%+', '%');
original_msg = regexprep(original_msg, '%[^%]+%', '');
msg = '';
i = 1;
while (n*i <= length(original_msg))
    msg = sprintf('%s%s<br>', msg, original_msg(n*(i-1) + 1: n*i));
    i = i + 1;
end
msg = sprintf('%s%s<br>', msg, original_msg(n*(i-1) + 1:end));
end