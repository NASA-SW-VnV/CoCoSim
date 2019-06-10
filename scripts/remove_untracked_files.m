%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script remove untracked files that do not belong to git.

function remove_untracked_files(coco_dir)

if nargin == 0
    script_path = fileparts(mfilename('fullpath'));
    coco_dir = fileparts(script_path);
end
PWD = pwd;

cd(coco_dir);
cmd = 'git ls-files --others ';
[status, git_output] = system(cmd);

if status==0
    untrackFiles = regexprep(git_output, '[\t\b]', '');
    lines = regexp(untrackFiles, '\n', 'split');
    parents = cell(1, numel(lines));
    for i=1:numel(lines)
        parents{i} = fileparts(lines{i});
        if ~strncmp(lines{i}, 'tools/', 6)
            cmd = sprintf('mv -f "%s" ~/.Trash/', lines{i});
            [status, ~] = system(cmd);
            if status == 0
                fprintf('file/repository %s has been successfully removed.\n', lines{i});
            else
                fprintf('file/repository %s could not be removed.\n', lines{i});
            end
        end
    end
    parents = unique(parents);
    I = cellfun(@(x) length(x), parents);
    [~, II] = sort(I, 'descend');
    parents = parents(II);
    parents = parents(cellfun(@(x) isdir(x), parents));
    % remove empty folders
    cellfun(@(x) MatlabUtils.rmdir(x), parents);
else
    fprintf('Git status command can not be run see error:\n%s\n', git_output);
end
cd(PWD);
end