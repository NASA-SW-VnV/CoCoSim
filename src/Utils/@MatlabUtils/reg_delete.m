%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% delete files using regular expressions:
%e.g. rm *_PP.slx
function reg_delete(basedir, reg_exp)
    all_files = dir(fullfile(basedir,'**', reg_exp));
    if isfield(all_files, 'folder')
        files_path = arrayfun(@(x) [x.folder '/' x.name], all_files, 'UniformOutput', 0);
    elseif isfield(all_files, 'name')
        files_path = {all_files.name};
    else
        files_path = {};
    end
    for i=1:numel(files_path)
        delete(files_path{i});
    end
end

