%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [mcdc_file] = generate_MCDCLustreFile(lus_full_path, output_dir)
    [~, lus_file_name, ~] = fileparts(lus_full_path);
    tools_config;
    status = BUtils.check_files_exist(LUSTRET);
    if status
        msg = 'LUSTRET not found, please configure tools_config file under tools folder';
        display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
        return;
    end
    command = sprintf('%s -I %s -d %s -mcdc-cond  %s',LUSTRET, LUCTREC_INCLUDE_DIR, output_dir, lus_full_path);
    msg = sprintf('LUSTRET_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
    [status, lustret_out] = system(command);
    if status
        msg = sprintf('lustret failed for model "%s"',lus_file_name);
        display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
        display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
        display_msg(msg, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
        display_msg(lustret_out, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
        return
    end

    mcdc_file = fullfile(output_dir,strcat( lus_file_name, '.mcdc.lus'));
    if ~exist(mcdc_file, 'file')
        display_msg(['No mcdc file has been found in ' output_dir ' with name ' ...
            strcat( lus_file_name, '.mcdc.lus')], MsgType.ERROR, 'generate_MCDCLustreFile', '');
        return;
    end

end
