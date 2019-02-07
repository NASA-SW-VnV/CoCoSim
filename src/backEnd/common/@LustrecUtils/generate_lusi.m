
function [lusi_path, status, lusi_out] = generate_lusi(lus_file_path, LUSTREC )
    % generate Lusi file
    lusi_out = '';
    [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
    lusi_path = fullfile(lus_dir,strcat(lus_fname, '.lusi'));
    if BUtils.isLastModified(lus_file_path, lusi_path)
        msg = sprintf('Lusi file "%s" already generated. It will be used.\n',lusi_path);
        display_msg(msg, MsgType.DEBUG, 'generate_lusi', '');
        status = 0;
        return;
    end
    msg = sprintf('generating lusi for "%s"\n',lus_file_path);
    display_msg(msg, MsgType.INFO, 'generate_lusi', '');
    command = sprintf('%s  -lusi  -d "%s" "%s"',...
        LUSTREC, lus_dir, lus_file_path);
    msg = sprintf('LUSI_LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generate_lusi', '');
    [status, lusi_out] = system(command);
    if status
        err = sprintf('generation of lusi file failed for file "%s" ',lus_fname);
        display_msg(err, MsgType.ERROR, 'generate_lusi', '');
        display_msg(err, MsgType.DEBUG, 'generate_lusi', '');
        display_msg(lusi_out, MsgType.DEBUG, 'generate_lusi', '');
        return
    end

end

