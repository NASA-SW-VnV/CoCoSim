%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%
function [emf_path, status] = ...
        generate_emf(lus_file_path, output_dir, ...
        LUSTREC,...
        LUSTREC_OPTS,...
        LUCTREC_INCLUDE_DIR)
    if nargin < 4
        tools_config;
        status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
        if status
            err = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
            display_msg(err, MsgType.ERROR, 'generate_lusi', '');
            return;
        end
    end
    [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
    if nargin < 2 || isempty(output_dir)
        output_dir = fullfile(lus_dir, 'cocosim_tmp', lus_fname);
    end

    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    emf_path = fullfile(output_dir,strcat(lus_fname, '.emf'));
    if BUtils.isLastModified(lus_file_path, emf_path)
        status = 0;
        msg = sprintf('emf file "%s" already generated. It will be used.\n',emf_path);
        display_msg(msg, MsgType.DEBUG, 'generate_emf', '');
        return;
    end
    msg = sprintf('generating emf "%s"\n',lus_file_path);
    display_msg(msg, MsgType.INFO, 'generate_emf', '');
    command = sprintf('%s %s -I "%s" -d "%s"  -emf  "%s"',...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR, output_dir, lus_file_path);
    msg = sprintf('EMF_LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generate_emf', '');
    [status, emf_out] = system(command);
    if status
        err = sprintf('generation of emf failed for file "%s" ',lus_fname);
        display_msg(err, MsgType.WARNING, 'generate_emf', '');
        display_msg(err, MsgType.DEBUG, 'generate_emf', '');
        display_msg(emf_out, MsgType.DEBUG, 'generate_emf', '');

        return
    end

end

