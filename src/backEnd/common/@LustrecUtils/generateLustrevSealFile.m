%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [seal_file, status] = generateLustrevSealFile(lus_full_path, output_dir, main_node, LUSTREV, LUCTREC_INCLUDE_DIR)
    [~, lus_file_name, ~] = fileparts(lus_full_path);
    seal_file = '';
    if nargin < 5 || BUtils.check_files_exist(LUSTREV, LUCTREC_INCLUDE_DIR)
        tools_config;
        status = BUtils.check_files_exist(LUSTREV);
        if status
            msg = 'LUSTRET not found, please configure tools_config file under tools folder';
            display_msg(msg, MsgType.ERROR, 'generateLustrevSealFile', '');
            return;
        end
    end
    z3librc = fullfile(LUCTREC_INCLUDE_DIR, 'z3librc');
    command = sprintf('source %s; %s -I %s -seal -seal-export lustre -d %s -node %s  %s',...
        z3librc, LUSTREV, LUCTREC_INCLUDE_DIR, output_dir, main_node, lus_full_path);
    msg = sprintf('LUSTREV_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generateLustrevSealFile', '');
    [status, lustrev_out] = system(command);
    if status
        msg = sprintf('lustrev failed for model "%s"',lus_file_name);
        display_msg(msg, MsgType.ERROR, 'generateLustrevSealFile', '');
        display_msg(msg, MsgType.DEBUG, 'generateLustrevSealFile', '');
        display_msg(lustrev_out, MsgType.DEBUG, 'generateLustrevSealFile', '');
        return
    end
    seal_name = strcat( lus_file_name, '_seal.lus');
    seal_file = fullfile(output_dir,seal_name);
    if ~exist(seal_file, 'file')
        display_msg(['No mcdc file has been found in ' output_dir ' with name ' ...
            seal_name], MsgType.ERROR, 'generateLustrevSealFile', '');
        return;
    end
    
end
