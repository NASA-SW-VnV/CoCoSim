%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function install_cocosim(force)
%INSTALL_COCOSIM is installing tools (such ass lustrec, kind2) and updating
%the external libraries.
persistent install_cocosim_already_run;
if isempty(install_cocosim_already_run)
    install_cocosim_already_run = 0;
else
    install_cocosim_already_run = 1;
end
if nargin <  1
    force = false;
end
if install_cocosim_already_run && ~force
    return;
end
PWD = pwd;

%% update cocosim
updateRepo()
%% copy files from cocosim in github
copyCoCoFiles(force);
%% install binaries: Zustre, Kind2, Lustrec, Z3 ...
install_tools();

cd(PWD);
end

%% update repo
function updateRepo()
cocosim_path = fileparts(mfilename('fullpath'));
cd(cocosim_path);
[status, sys_out] = system('git pull', '-echo'); 
if status
    fprintf('Can not run git:\n%s \n', sys_out) ;
    return;
end
end

%%
function copyCoCoFiles(force)
cocosim_path = fileparts(mfilename('fullpath'));
build_dir = fullfile(cocosim_path, 'tools', 'build');
coco_git_dir = fullfile(build_dir, 'github', 'cocosim');
cocosim_url = 'https://github.com/coco-team/cocoSim2.git';
cocosim_branch = 'cocosim_nasa';

if exist(coco_git_dir, 'dir')
    cd(coco_git_dir); 
    commands = {sprintf('git pull; git checkout %s', cocosim_branch), ...
        sprintf('git pull origin %s', cocosim_branch)};
else
    MatlabUtils.mkdir(coco_git_dir); 
    cd(coco_git_dir)
    commands = {' git init; touch .gitconfig; git config --local http.sslverify false', ...
        sprintf('git remote add -f origin %s', cocosim_url), ...
        sprintf('git pull origin %s', cocosim_branch)};
end
for i=1:numel(commands)
    [status, sys_out] = system(commands{i}, '-echo');
    if status
        fprintf('Can not run git:\n%s \n', sys_out) ;
        return;
    end
end
if ~force && contains(sys_out, 'Already up to date.')
    %no need to copy files, nothing new from github
    return;
end
fprintf('Copying files from cocosim2 in tools/build\n');
sources = {'doc', 'examples', 'libs', 'PreContextMenu.m', ...
    fullfile('src', 'gui'), ...
    fullfile('src', 'miscellaneous'), ...
    fullfile('src', 'preferences'), ...
    fullfile('src', 'utils'), ...
    fullfile('src', 'frontEnd', 'pp'), ...
    fullfile('src', 'frontEnd', 'IR'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler'), ...
    fullfile('src', 'middleEnd', 'cocoSpecCompiler'),...
    fullfile('src', 'backEnd', 'common'), ...
    fullfile('src', 'backEnd', 'templates'), ...
    fullfile('src', 'backEnd', 'verification')};
destinations = {'doc', 'examples', 'libs',  'PreContextMenu.m', ...
    fullfile('src', 'gui'), ...
    fullfile('src', 'miscellaneous'), ...
    fullfile('src', 'preferences'), ...
    fullfile('src', 'utils'), ...
    fullfile('src', 'frontEnd', 'pp', 'std_pp'), ...
    fullfile('src', 'frontEnd', 'IR', 'std_IR'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler1'), ...
    fullfile('src', 'middleEnd', 'lustre_compiler2'),...
    fullfile('src', 'backEnd', 'common'),...
    fullfile('src', 'backEnd', 'templates'), ...
    fullfile('src', 'backEnd', 'verification')};
for i=1:numel(sources)
    fprintf('Copying files from tools/build/github/cocosim/%s to %s\n', sources{i}, destinations{i}) ;
    [SUCCESS,MESSAGE,~] = copyfile(fullfile(coco_git_dir, sources{i}), ...
        fullfile(cocosim_path, destinations{i}));
    if ~SUCCESS
        fprintf('copyfile failed:\n%s \n', MESSAGE);
    end
end

delete(fullfile(cocosim_path, 'src', 'frontEnd', 'pp', 'std_pp', 'cocosim_pp.m'));

end
%%
function install_tools()
tools_config;
if exist(LUSTREC,'file') || exist(ZUSTRE,'file') || exist(KIND2,'file')
    % the user has at least one of the tools.
    return;
end
scripts_path = fullfile(fileparts(mfilename('fullpath')), 'scripts');

if ispc
    installation_path = fullfile(fileparts(mfilename('fullpath')), 'doc', 'installation.md');
    fprintf('ONLY kind2 can be used in Windows. follow the instructions <a href="matlab: open %s">here</a>\n', installation_path) ;
    return;
elseif ismac
    % create executable script adapted to the user.
    tmp_sh = fullfile(scripts_path, 'install_cocosim_tmp.sh');
    fid = fopen(tmp_sh,'w+');
    if fid < 0
        fprintf('Can not creat file %s\n', tmp_sh) ;
        fprintf('Please run the following commands in your terminal.\n' );
        fprintf('>> cd %s\n', scripts_path) ;
        fprintf('>> ./install_cocosim\n' );
        return;
    end
    fprintf(fid, 'cd %s;\n', scripts_path);
    fprintf(fid, './install_cocosim');
    fclose(fid);
    [status,~] = system(sprintf('chmod +x %s', tmp_sh), '-echo');
    if status
        fprintf('Can not chmod file %s to executable\n', tmp_sh) ;
        return;
    end
    [status,~] = system(sprintf('open -a Terminal %s', tmp_sh), '-echo');
    if status
        fprintf('Can not launch executable %s\n', tmp_sh) ;
        return;
    end
    
else
    % Unix case
    fprintf('Please run the following commands in your terminal.\n' );
    fprintf('>> cd %s\n', scripts_path);
    fprintf('>> ./install_cocosim\n');
end
end