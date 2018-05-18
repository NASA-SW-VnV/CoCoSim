%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate C code from lustre file using lustrec tool.
function lustrec_C_code(lus_full_path, output_dir, node_name)

[lus_path, fname, ~] = fileparts(lus_full_path);
if nargin < 2
    output_dir = fullfile(lus_path, strcat(fname, '_lustrec_C_code'));
end

if nargin < 3
    node_name = fname;
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end


tools_config;
status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
if status
    msg = 'LUSTREC not found, please configure tools_config file under tools folder';
    display_msg(msg, MsgType.ERROR, 'lustrec_C_code', '');
    return;
end


command = sprintf('%s %s -I "%s" -d "%s" -node %s "%s"', LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR, output_dir, lus_full_path, node_name);
[~, lustrec_output] = system(command);
if ~contains(lustrec_output, '.. done')
    display_msg('Error Generating C code', Constants.ERROR, 'C Generation', '');
    display_msg(lustrec_output, MsgType.ERROR, 'Rust Generation', '');
else
    msg = ['C code is generated in :  ' output_dir] ;
    display_msg(msg, Constants.RESULT, 'C Generation', '');
end
end
