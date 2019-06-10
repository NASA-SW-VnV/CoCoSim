%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function F = allMatlabFilesExceeds(folder, n)
    mfiles = dir(fullfile(folder,'**', '*.m'));
    if isfield(mfiles, 'folder')
        files_path = arrayfun(@(x) [x.folder '/' x.name], mfiles, 'UniformOutput', 0);
    else
        files_path = {mfiles.name};
    end
    count = cellfun(@(x) MatlabUtils.getNbLines(x), files_path, 'UniformOutput', true);
    F = files_path(count > n);
end
        

    


