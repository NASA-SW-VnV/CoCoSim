function blkParams = readBlkParams(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.utils.SLX2LusUtils
    blkParams = struct;
    blkParams.OutputAfterFinalValue = blk.Content.FromWs.OutputAfterFinalValue;
    blkParams.blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
end
