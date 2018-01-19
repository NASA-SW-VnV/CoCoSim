function [ T ] = lustret_test_mcdc( lus_full_path, output_dir)
%lustret_test_mcdc generates unit tests of Lustre nodes based on MC/DC
%coverage.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


T = [];
if nargin < 2
    print_help_messsage();
    return;
end
[~, lus_file_name, ~] = fileparts(lus_full_path);

Pwd = pwd;

%% generate MC/DC conditions
tools_config;
status = BUtils.check_files_exist(LUSTRET);
if status
    msg = 'LUSTRET not found, please configure tools_config file under tools folder';
    display_msg(msg, MsgType.ERROR, 'lustret_test_mcdc', '');
    return;
end



command = sprintf('%s -I %s -d %s -mcdc-cond  %s',LUSTRET, LUCTREC_INCLUDE_DIR, output_dir, lus_full_path);
msg = sprintf('LUSTRET_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_test_mcdc', '');
display_msg('Please Kill me (Ctrl+C) if I am taking long time',...
    MsgType.INFO, 'lustret_test_mcdc', '');
[status, lustret_out, lustret_out2] = cmd(command,7);
if status
    msg = sprintf('lustret failed for model "%s"',lus_file_name);
    display_msg(msg, MsgType.INFO, 'lustret_test_mcdc', '');
    display_msg(msg, MsgType.ERROR, 'lustret_test_mcdc', '');
    display_msg(msg, MsgType.DEBUG, 'lustret_test_mcdc', '');
    display_msg([lustret_out, lustret_out2], MsgType.DEBUG, 'lustret_test_mcdc', '');
    return
end

mcdc_file = fullfile(output_dir,strcat( lus_file_name, '.mcdc.lus'));
mcdc_file_tmp = fullfile(output_dir,strcat( lus_file_name, '_tmp.mcdc.lus'));

if ~exist(mcdc_file, 'file')
    display_msg(['No mcdc file has been found in ' output_dir], MsgType.ERROR, 'lustret_test_mcdc', '');
    cd(Pwd);
    return;
end

% adapt lustre code
fid = fopen(mcdc_file_tmp, 'w');
if fid > 0
    fprintf(fid, '%s', LustrecUtils.adapt_lustre_text(fileread(mcdc_file)));
    fclose(fid);
else
    mcdc_file_tmp = mcdc_file;
end


%% Use model checker to find mcdc CEX if exists
[~, T, ~] = LustrecUtils.run_Kind2(mcdc_file_tmp, output_dir);



cd(Pwd);
end

function print_help_messsage()
msg = 'LUSTRET_TEST_MCDC is generating test cases based on MC/DC in Lustre code\n';
msg = [msg, '\n   Usage: \n '];
msg = [msg, '\n     lustret_test_mcdc( lus_full_path, output_dir ) \n\n '];
msg = [msg, '\t     lus_full_path: is the full path of the lustre file that correspond to the Simulink model. \n'];
msg = [msg, '\t     output_dir: is the full path of the output directory where to produce temporal files. \n'];

cprintf('blue', msg);
end