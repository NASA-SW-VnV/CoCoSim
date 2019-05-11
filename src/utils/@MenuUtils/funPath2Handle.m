function handle = funPath2Handle(fullpath)
    %% get function handle from its path
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    oldDir = pwd;
    [dirname,funName,~] = fileparts(which(fullpath));
    cd(dirname);
    handle = str2func(funName);
    cd(oldDir);
end

