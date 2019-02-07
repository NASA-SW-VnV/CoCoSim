
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
        

    


