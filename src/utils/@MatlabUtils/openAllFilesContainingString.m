%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function openAllFilesContainingString(folder, str)
    [~, A] = system(sprintf('find %s | xargs grep "%s" -sl', folder, str), '-echo');
    AA = strsplit(A, '\n');
    for i=1:numel(AA), try open(AA{i}), catch, end, end
end
        
