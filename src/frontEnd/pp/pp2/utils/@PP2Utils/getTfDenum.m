function [denum, status] = getTfDenum(model,blk, ppName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    denum_str = get_param(blk, 'Denominator');
    [denum, ~, status] = SLXUtils.evalParam(...
        model, ...
        get_param(blk, 'Parent'), ...
        blk, ...
        denum_str);
    if status
        display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
            denum_str, blk), ...
            MsgType.ERROR, ppName, '');
    end
end



