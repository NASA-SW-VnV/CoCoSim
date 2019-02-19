% function to search folder and subfolder for string

searchStr = 'Copyright (c)';
searchType = {'.m'};
workDir = '/Users/ktrinh/cocosim/cocosim2/src';

dirInfo = dir(workDir);
fprintf('search % and its subfolders for string %s',workDir,searchStr);
[numFileRead, numFileModified, typesFound] = ...
    search_folder_and_subfolders_for_string(dirInfo,searchStr,searchType);
fprintf('number of file read: %d\n',nRead);
fprintf('number of file modified: %d\n',numFileModified);

for j=1:numel(typesFound)
    fprintf('file type found: %s\n',typesFound{j});
end



