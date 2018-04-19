function install_cocosim()
%INSTALL_COCOSIM is installing tools (such ass lustrec, kind2) and updating
%the external libraries.
scripts_path = fullfile(fileparts(mfilename('fullpath')), 'scripts');

if ispc
elseif ismac
    % create executable script adapted to the user.
    tmp_sh = fullfile(scripts_path, 'install_cocosim_tmp.sh');
    fid = fopen(tmp_sh,'w+');
    if fid < 0
        display_msg(sprintf('Can not creat file %s', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
    end
    fprintf(fid, 'cd %s;\n', scripts_path);
    fprintf(fid, './install_cocosim');
    fclose(fid);
    [status,~] = system(sprintf('chmod +x %s', tmp_sh));
    if status
        display_msg(sprintf('Can not chmod file %s to executable', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
    end
    [status,~] = system(sprintf('open -a Terminal %s', tmp_sh));
    if status
        display_msg(sprintf('Can not launch executable %s', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
    end
    
else
    % Unix case
    display_msg('Please run the following commands in your terminal.', ...
        MsgType.ERROR, 'INSTALL_COCOSIM', '');
    display_msg(sprintf('>> cd %s', scripts_path), ...
        MsgType.ERROR, 'INSTALL_COCOSIM', '');
    display_msg('>> ./install_cocosim', ...
        MsgType.ERROR, 'INSTALL_COCOSIM', '');
end

end