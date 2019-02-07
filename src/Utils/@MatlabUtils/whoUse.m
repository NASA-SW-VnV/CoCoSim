%% This function for developers
% open all files that contains a String
function whoUse(folder, str)
    system(sprintf('find %s | xargs grep "%s" -sl', folder, str), '-echo');
end
