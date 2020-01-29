function ExecutionCondName = getExecutionCondName(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    ExecutionCondName = sprintf('ExecutionCond_of_%s', blk_name);
end
