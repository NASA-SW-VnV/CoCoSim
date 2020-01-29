%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function install_cocosim_lib(force)

    %INSTALL_COCOSIM is doing all the following:
    %   1- Update cocosim repo from git. To get the latest version of cocosim
    %   2- It copy all required files from external libraries. This is
    %   important so CoCoSim can run properly.
    %   3- Install CoCoSim dependancies such as model checkers Kind2, Zustre,
    %   Lustrec...
    
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
    [status, ~] = system('ping -c1 -q google.com');
    if status
        %No netwrok connexion
        return;
    end
    scripts_path = fileparts(mfilename('fullpath'));
    cocosim_path = fileparts(scripts_path);
    %% update cocosim
    updateRepo(cocosim_path)
    %% copy files from cocosim in github
    copyCoCoFiles(force, cocosim_path);
    %% copy file from external libraries : Autolayout, cmd_timeout, html_lib
    copyExternalLibFiles(force, cocosim_path);
    %% install binaries: Zustre, Kind2, Lustrec, Z3 ...
    install_tools(cocosim_path);
    
    cd(PWD);
end

%% update repo
function updateRepo(cocosim_path)
    cd(cocosim_path);
    [status, sys_out] = system('git pull origin $(git rev-parse --abbrev-ref HEAD)', '-echo');
    if status
        fprintf('Can not update current git repository:\n%s \n', sys_out) ;
        return;
    end
end
%% clone and pull
function isAlreadyUpToDate = cloneOrPull(git_dir, git_url, git_branch)
    isAlreadyUpToDate = false;
    if exist(git_dir, 'dir')
        cd(git_dir);
        commands = {sprintf('git checkout %s', git_branch), ...
            sprintf('git pull origin %s', git_branch)};
        pull_idex = 2;
    else
        MatlabUtils.mkdir(git_dir);
        cd(git_dir)
        commands = {' git init; touch .gitconfig; git config --local http.sslverify false', ...
            sprintf('git remote add -f origin %s', git_url), ...
            sprintf('git pull origin %s', git_branch)};
        pull_idex = 3;
    end
    sys_out = cell(numel(commands), 1);
    for i=1:numel(commands)
        [status, sys_out{i}] = system(commands{i}, '-echo');
        if status
            fprintf('Can not run git:\n%s \n', sys_out{i}) ;
            return;
        end
    end
    isAlreadyUpToDate = MatlabUtils.contains(sys_out{pull_idex}, 'Already up to date.');
end
%%
function copyCoCoFiles(force, cocosim_path)
    % add utils to the path. Some function as MatlabUtils is used here
    addpath(fullfile(cocosim_path,'src', 'utils'))
    
    build_dir = fullfile(cocosim_path, 'tools', 'build');
    coco_git_dir = fullfile(build_dir, 'github', 'cocosim');
    cocosim_url = 'https://github.com/coco-team/cocoSim2.git';
    cocosim_branch = 'cocosim_nasa';
    
    isAlreadyUpToDate = cloneOrPull(coco_git_dir, cocosim_url, cocosim_branch);
    if ~force && isAlreadyUpToDate
        %no need to copy files, nothing new from github
        return;
    end
    
    fprintf('Copying files from cocosim2 in tools/build\n');
    sources = {...
        fullfile('doc', 'installation.md'), ...
        fullfile('doc', 'specificationLibrary.md'), ...
        fullfile('examples', 'contract'), ...
        'libs', ...
        fullfile('src', 'gui'), ...
        fullfile('src', 'miscellaneous', 'MiscellaneousMenu.m'), ...
        fullfile('src', 'preferences'), ...
        fullfile('src', 'utils'), ...
        'LICENSE',...
        fullfile('src', 'frontEnd', 'pp'), ...
        fullfile('src', 'frontEnd', 'IR'), ...
        fullfile('src', 'middleEnd', 'cocoSpecCompiler'),...
        fullfile('src', 'backEnd', 'common'), ...
        fullfile('src', 'backEnd', 'templates'), ...
        fullfile('src', 'backEnd', 'verification', 'cocoSpecVerify'),...
        fullfile('src', 'backEnd', 'verification', 'VerificationMenu.m')...
        };
    destinations = {...
        fullfile('doc', 'cocosim_iowa_doc', 'installation.md'), ...
        fullfile('doc', 'cocosim_iowa_doc', 'specificationLibrary.md'), ...
        fullfile('examples', 'contract'), ...
        'libs',  ...
        fullfile('src', 'external', 'cocosim_iowa', 'gui'), ...
        fullfile('src', 'external', 'cocosim_iowa', 'miscellaneous', 'MiscellaneousMenu.m'), ...
        fullfile('src', 'external', 'cocosim_iowa', 'preferences'), ...
        fullfile('src', 'external', 'cocosim_iowa', 'utils'), ...
        fullfile('src', 'external', 'cocosim_iowa', 'LICENSE'), ...
        fullfile('src', 'frontEnd', 'pp', 'std_pp'), ...
        fullfile('src', 'frontEnd', 'IR', 'std_IR'), ...
        fullfile('src', 'middleEnd', 'iowa_toLustre'),...
        fullfile('src', 'backEnd', 'common'),...
        fullfile('src', 'backEnd', 'templates'), ...
        fullfile('src', 'backEnd', 'verification', 'cocoSpecVerify'),...
        fullfile('src', 'backEnd', 'verification', 'VerificationMenu.m')...
        };
    for i=1:numel(sources)
        
        fprintf('Copying files from tools/build/github/cocosim/%s to %s\n', sources{i}, destinations{i}) ;
        dst_path = fullfile(cocosim_path, destinations{i});
        if ~exist(dst_path, 'file') && ~exist(dst_path, 'dir')
            if MatlabUtils.contains(dst_path, '.')
                MatlabUtils.mkdir(fileparts(dst_path));
            else
                MatlabUtils.mkdir(dst_path);
            end
        end
        [SUCCESS,MESSAGE,~] = copyfile(fullfile(coco_git_dir, sources{i}), dst_path);
        if ~SUCCESS
            fprintf('copyfile failed:\n%s \n', MESSAGE);
        end
    end
    %delete old cocosim_pp
    delete(fullfile(cocosim_path, 'src', 'frontEnd', 'pp', 'std_pp', 'cocosim_pp.m'));
    
    %add path the new folder
    addpath(genpath(cocosim_path));
    rmpath(genpath(fullfile(cocosim_path, 'tools')));
    %add only tools not its sub-folders
    addpath(fullfile(cocosim_path, 'tools'));
    
    
end
%%
function copyExternalLibFiles(force, cocosim_path)
    % add utils to the path. Some function as MatlabUtils is used here
    addpath(fullfile(cocosim_path,'src', 'utils'))
    
    build_dir = fullfile(cocosim_path, 'tools', 'build');
    externalLibs_git_dir = fullfile(build_dir, 'github', 'externalLib');
    externalLibs_url = 'https://github.com/hbourbouh/cocosim-external-libs.git';
    externalLib_branch = 'master';
    
    isAlreadyUpToDate = cloneOrPull(externalLibs_git_dir, externalLibs_url, externalLib_branch);
    if ~force && isAlreadyUpToDate
        %no need to copy files, nothing new from github
        return;
    end
    fprintf('Copying files from external libraries in tools/build/externalLib\n');
    sources = {...
        '+AutoLayout', ...
        '+cmd_timeout', ...
        'html_lib', ...
        'jkind'};
    destinations = {...
        fullfile('src', 'external', '+external_lib', '+AutoLayout'), ...
        fullfile('src', 'external', '+external_lib', '+cmd_timeout'), ...
        fullfile('src', 'external', 'html_lib'), ...
        fullfile('tools', 'verifiers', 'jkind')};
    for i=1:numel(sources)
        
        fprintf('Copying files from tools/build/github/externalLib/%s to %s\n', sources{i}, destinations{i}) ;
        dst_path = fullfile(cocosim_path, destinations{i});
        if ~exist(dst_path, 'file') && ~exist(dst_path, 'dir')
            if MatlabUtils.contains(dst_path, '.')
                MatlabUtils.mkdir(fileparts(dst_path));
            else
                MatlabUtils.mkdir(dst_path);
            end
        end
        [SUCCESS,MESSAGE,~] = copyfile(fullfile(externalLibs_git_dir, sources{i}), dst_path);
        if ~SUCCESS
            fprintf('copyfile failed:\n%s \n', MESSAGE);
        end
    end
    
    %TODO add patch to break word
    file_path  = fullfile(cocosim_path, destinations{3}, 'materialize/css/materialize.css');
    fprintf('Patching %s\n', file_path);
    try
        file_content = fileread(file_path);
        rule = regexp(file_content, '\n\.collapsible-header \{');
        expr_list = strfind(file_content, 'word-break: break-all;');
        expr = expr_list(expr_list > rule);
        new_expr = 'word-break: break-word;';
        file_content(expr:expr+numel(new_expr)-1) = new_expr;
        fID = fopen(file_path, 'w');
        fwrite(fID, file_content);
        fclose(fID);
    catch ME
        switch ME.identifier
            case 'MATLAB:fileread:cannotOpenFile'
                fprintf('Patch failed: Can''t open file %s', file_path);
            otherwise
                rethrow(ME)
        end
    end
end
%%
function install_tools(cocosim_path)
    addpath(fullfile(cocosim_path, 'tools'));
    tools_config;
    if exist(LUSTREC,'file') || exist(ZUSTRE,'file') || exist(KIND2,'file')
        % the user has at least one of the tools.
        return;
    end
    scripts_path = fullfile(cocosim_path, 'scripts');
    
    if ispc
        installation_path = fullfile(cocosim_path, 'doc', 'installation.md');
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