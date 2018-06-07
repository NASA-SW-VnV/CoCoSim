%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function install_cocosim()
%INSTALL_COCOSIM is installing tools (such ass lustrec, kind2) and updating
%the external libraries.
PWD = pwd;
%% copy files from cocosim in github
copyCoCoFiles();
%% install binaries: Zustre, Kind2, Lustrec, Z3 ...
% install_tools();

cd(PWD);
end

%%
function copyCoCoFiles()
cocosim_path = fileparts(mfilename('fullpath'));
build_dir = fullfile(cocosim_path, 'tools', 'build');
coco_git_dir = fullfile(build_dir, 'github', 'cocosim');
cocosim_url = 'https://github.com/coco-team/cocoSim2.git';
cocosim_branch = 'master';

if exist(coco_git_dir, 'dir')
    cd(coco_git_dir);
    commands = {sprintf('git checkout %s', cocosim_branch), ...
        sprintf('git pull origin %s', cocosim_branch)};
else
    MatlabUtils.mkdir(coco_git_dir);
    cd(coco_git_dir)
    commands = {'git init', ...
        sprintf('git remote add -f origin %s', cocosim_url), ...
        sprintf('git pull origin %s', cocosim_branch)};
end
for i=1:numel(commands)
    [status, sys_out] = system(commands{i}, '-echo');
    if status
        display_msg(sprintf('Can not run git:\n%s ', sys_out), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        return;
    end
end


sources = {'doc', 'examples', 'libs', ...
    fullfile('src', 'frontEnd', 'pp'), ...
    fullfile('src', 'frontEnd', 'IR'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler'), ...
    fullfile('src', 'middleEnd', 'cocoSpecCompiler'),...
    fullfile('src', 'backEnd', 'common'), ...
    fullfile('src', 'backEnd', 'templates'), ...
    fullfile('src', 'backEnd', 'verification', 'cocoSpecVerify')};
destinations = {'doc', 'examples', 'libs',  ...
    fullfile('src', 'frontEnd', 'pp', 'std_pp'), ...
    fullfile('src', 'frontEnd', 'IR', 'std_IR'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler1'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler2'),...
    fullfile('src', 'backEnd', 'common'),...
    fullfile('src', 'backEnd', 'templates'), ...
    fullfile('src', 'backEnd', 'verification', 'cocoSpecVerify')};
for i=1:numel(sources)
    [SUCCESS,MESSAGE,~] = copyfile(fullfile(coco_git_dir, sources{i}), ...
        fullfile(cocosim_path, destinations{i}));
    if ~SUCCESS
        display_msg(sprintf('copyfile failed:\n%s ', MESSAGE), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
    end
end

delete(fullfile(cocosim_path, 'src', 'frontEnd', 'pp', 'std_pp', 'cocosim_pp.m'));

end
%%
function install_tools()
scripts_path = fullfile(fileparts(mfilename('fullpath')), 'scripts');

if ispc
elseif ismac
    % create executable script adapted to the user.
    tmp_sh = fullfile(scripts_path, 'install_cocosim_tmp.sh');
    fid = fopen(tmp_sh,'w+');
    if fid < 0
        display_msg(sprintf('Can not creat file %s', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        display_msg('Please run the following commands in your terminal.', ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        display_msg(sprintf('>> cd %s', scripts_path), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        display_msg('>> ./install_cocosim', ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        return;
    end
    fprintf(fid, 'cd %s;\n', scripts_path);
    fprintf(fid, './install_cocosim');
    fclose(fid);
    [status,~] = system(sprintf('chmod +x %s', tmp_sh), '-echo');
    if status
        display_msg(sprintf('Can not chmod file %s to executable', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        return;
    end
    [status,~] = system(sprintf('open -a Terminal %s', tmp_sh), '-echo');
    if status
        display_msg(sprintf('Can not launch executable %s', tmp_sh), ...
            MsgType.ERROR, 'INSTALL_COCOSIM', '');
        return;
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