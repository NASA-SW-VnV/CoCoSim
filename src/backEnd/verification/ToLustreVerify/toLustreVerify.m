function [ ] = toLustreVerify(model_full_path,  const_files, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('const_files', 'var') || isempty(const_files)
    const_files = {};
end

[nom_lustre_file, xml_trace]= ToLustre(model_full_path, const_files,...
    BackendType.KIND2, varargin);


% Get start time
t_start = now;

mapping_file = xml_trace.json_file_path;

if (exist(mapping_file,'file') == 2)
    display_msg('Running Kind2', Constants.INFO, 'toLustreVerify', '');
    try
        cocoSpecKind2(nom_lustre_file, mapping_file);
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'toLustreVerify', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'toLustreVerify', '');
    end
else
    display_msg(sprintf('Mapping file %s is missing', mapping_file), MsgType.ERROR, 'toLustreVerify', '');
end

t_end = now;
t_compute = t_end - t_start;
display_msg(['Total verification time: ' datestr(t_compute, 'HH:MM:SS.FFF')], Constants.RESULT, 'Time', '');
end
