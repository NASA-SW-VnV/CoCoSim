function [Value, valueDataType, status] = ...
        getValueFromParameter(parent, blk, param)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    model_name = regexp(blk.Origin_path, filesep, 'split');
    model_name = model_name{1};
    [Value, valueDataType, status] = ...
        SLXUtils.evalParam(model_name, parent, blk, param);
end
