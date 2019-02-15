function [num, status] = getTfNumerator(model,blk,numStr,ppName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    
    num_str = get_param(blk,numStr);
    [num, ~, status] = SLXUtils.evalParam(...
        model, ...
        get_param(blk, 'Parent'), ...
        blk, ...
        num_str);
    if status
        display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
            num_str, blk), ...
            MsgType.ERROR, ppName, '');
    end
end

