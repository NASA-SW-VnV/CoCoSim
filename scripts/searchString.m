% function to search folder and subfolder for string

searchStr = 'Copyright (c)';
workDir = '/Users/ktrinh/cocosim/cocosim2/src';

dirInfo = dir(workDir);
fprintf('search % and its subfolders for string %s',workDir,searchStr);
[numFileRead, numFileModified] = search_folder_and_subfolders_for_string(dirInfo,searchStr);
fprintf('number of file read: %d\n',nRead);
fprintf('number of file modified: %d\n',numFileModified);


