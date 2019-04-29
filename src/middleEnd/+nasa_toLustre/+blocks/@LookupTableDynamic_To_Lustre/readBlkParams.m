function blkParams = readBlkParams(~,blk,inputs,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LookupTableDynamic_To_Lustre
    
    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.LookupDynamic;

    % read blk
    blkParams.NumberOfTableDimensions = 1;
    blkParams.NumberOfAdjustedTableDimensions = blkParams.NumberOfTableDimensions;
    blkParams.BreakpointsForDimension{1} = inputs{2};
    % table
    blkParams.Table = inputs{3};
    blkParams.numberTableData=numel(blkParams.Table);  
    % look up method
    if strcmp(blk.LookUpMeth, 'Interpolation-Extrapolation')
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod = 'Linear';
    elseif strcmp(blk.LookUpMeth, 'Interpolation-Use End Values')
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Nearest')
        blkParams.InterpMethod = 'Nearest';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Below')
        blkParams.InterpMethod = 'Flat';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Above')
        blkParams.InterpMethod = 'Above';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.InterpMethod, 'Cubic spline')
        display_msg(sprintf('Cubic spline interpolation in block %s is not supported',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
    else
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod = 'Linear';
    end
    
    blkParams.RndMeth = blk.RndMeth;
end

