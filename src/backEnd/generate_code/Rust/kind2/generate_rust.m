%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate rust code from lustre file using Kind2 tool.
function generate_rust(lus_full_path, output_dir)

[lus_path, fname, ~] = fileparts(lus_full_path);
if nargin < 2
    output_dir = fullfile(lus_path, strcat(fname, '_rust_code'));
end
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
tools_config;

if ~exist(KIND2,'file')
    msg = 'Kind2 not found, please configure tools_config file under tools folder';
    display_msg(msg, MsgType.ERROR, 'generate_rust', '');
    return;
end

command = sprintf('%s --compile true --z3_bin %s --output_dir %s --check_implem false %s', KIND2, Z3, output_dir, lus_full_path);
display_msg(['KIND2_COMMAND ' command], MsgType.INFO, 'generate_rust', '');
[~, rust_output] = system(command);
if ~MatlabUtils.contains(rust_output, 'Success')
    display_msg('Error Generating Rust code', MsgType.ERROR, 'Rust Generation', '');
    display_msg(rust_output, MsgType.ERROR, 'Rust Generation', '');
else
    msg = ['Rust code is generated in :  ' output_dir] ;
    display_msg(msg, MsgType.INFO, 'generate_rust', '');
end



end
