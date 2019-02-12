
% Adapt BlockType to the name of the class that will handle its
%translation.
function name = blkTypeFormat(name)
    name = strrep(name, ' ', '');
    name = strrep(name, '-', '');
end
