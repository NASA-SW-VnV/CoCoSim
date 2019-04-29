function output = addTryCatch(callbackInfo)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    funcHandle = callbackInfo.userdata;
    output = [];
    try
        output = funcHandle(callbackInfo);
    catch ME
        MenuUtils.handleExceptionMessage(ME, '');
    end
end

