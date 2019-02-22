%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function rmdir(path)
    % recursively rmdir empty folders from bottom to top
    warning('off', 'MATLAB:RMDIR:RemovedFromPath')
    warning off MATLAB:rmpath:DirNotFound
    try
        rmdir(path);
        MatlabUtils.rmdir(fileparts(path));
    catch
    end
    warning('on', 'MATLAB:RMDIR:RemovedFromPath')
    warning on MATLAB:rmpath:DirNotFound
    return;
    
end
