%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function status = rmdir(path)
    % recursively rmdir empty folders from bottom to top
    status = 0;
    warning('off', 'MATLAB:RMDIR:RemovedFromPath')
    warning off MATLAB:rmpath:DirNotFound
    try
        rmdir(path);
        MatlabUtils.rmdir(fileparts(path));
    catch
        status = 1;
    end
    warning('on', 'MATLAB:RMDIR:RemovedFromPath')
    warning on MATLAB:rmpath:DirNotFound
    return;
    
end
