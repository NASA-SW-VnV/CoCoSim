function importLusReqGui(model_full_path)
%importLusReqGui  This is a html page enables the user to upload Lustre
%file containing requirements about the simulink model in parameter.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cocoSim_path = fileparts(which('start_cocosim'));
css_source = fullfile(cocoSim_path, 'src', 'external', 'html_lib',...
    'materialize' , 'css' , 'materialize.css');

% change the css path
html_text = fileread(fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'importLusReq.html'));
html_text = strrep(html_text, '[css_source]', css_source);
html_text = strrep(html_text, '[model_full_path]', model_full_path);
% create temporal file
tmp_dir  = fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'tmp');
html_path = fullfile(tmp_dir, 'importLusReq_local.html');
if ~exist(tmp_dir, 'dir')
    mkdir(tmp_dir);
end
fid = fopen(html_path, 'w+');
if ~strcmp(html_text, '')
    fprintf(fid, html_text);
    open(html_path);
end
end

%%
function msg = divide_msg(original_msg, n)
msg = '';
i = 1;
while (n*i <= length(original_msg))
    msg = sprintf('%s%s<br>', msg, original_msg(n*(i-1) + 1: n*i));
    i = i + 1;
end
msg = sprintf('%s%s<br>', msg, original_msg(n*(i-1) + 1:end));
end