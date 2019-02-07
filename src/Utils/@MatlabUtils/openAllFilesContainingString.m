
function openAllFilesContainingString(folder, str)
    [~, A] = system(sprintf('find %s | xargs grep "%s" -sl', folder, str), '-echo');
    AA = strsplit(A, '\n');
    for i=1:numel(AA), try open(AA{i}), catch, end, end
end
        
