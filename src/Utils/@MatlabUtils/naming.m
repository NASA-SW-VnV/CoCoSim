
function out = naming(nomsim)
    [a, ~]=regexp (nomsim, '/', 'split');
    out = strcat(a{numel(a)-1},'_',a{end});
end

