%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script remove untracked files that do not belong to git.


script_path = fileparts(mfilename('fullpath'));
coco_dir = fileparts(script_path);
PWD = pwd;

cd(coco_dir);
cmd = sprintf('git status');
[status, git_output] = system(cmd);

if status==0
    untrackFiles = regexp(git_output, 'Untracked files', 'split');
    untrackFiles = untrackFiles{end};
    untrackFiles = regexprep(untrackFiles, '[\t\b]', '')
    lines = regexp(untrackFiles, '\n', 'split');
    for i=1:numel(lines)
        l = char(lines{i});
        if strncmp(lines{i}, 'src/', 4) || strncmp(lines{i}, 'libs/', 5) ...
                || strncmp(lines{i}, 'test/', 5)
            cmd = sprintf('rm -rf %s', lines{i});
            [status, ~] = system(cmd);
            if status == 0
                fprintf('file/repository %s has been removed successfully.\n', lines{i});
            else
                fprintf('file/repository %s could not be removed.\n', lines{i});
            end
        end
    end
else
    fprintf('Git status command can not be run see error:\n%s\n', git_output);
end

cd(PWD);