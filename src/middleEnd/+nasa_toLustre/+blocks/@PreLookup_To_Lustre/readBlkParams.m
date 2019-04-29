function blkParams = readBlkParams(~,parent,blk,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PreLookup_To_Lustre

    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.PreLookup;
    blkParams.OutputIndexOnly = 0;

    % read blk
    blkParams.NumberOfTableDimensions = 1;
    blkParams.NumberOfAdjustedTableDimensions = 1;
    % read blk    
    % read breakpoints
    
    if strcmp(blk.BreakpointsSpecification, 'Breakpoint object')
        display_msg(sprintf('Breakpoint object for BreakpointsSpecification in block %s is not supported',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'PreLookup_To_Lustre', '');
    end    
    
    if strcmp(blk.BreakpointsSpecification, 'Even spacing')
        [firstPoint, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.BreakpointsFirstPoint);
        [spacing, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.BreakpointsSpacing);
        [breakpointsNumPoints, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.BreakpointsNumPoints);
        curBreakPoint = [];        
        for j=1:breakpointsNumPoints
            curBreakPoint(j) = firstPoint + (j-1)*spacing;
        end
        blkParams.BreakpointsForDimension{1} = curBreakPoint;
    else
        [blkParams.BreakpointsForDimension{1}, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.BreakpointsData);
    end
    %cast breakpoints
    validDT = {'double', 'single', 'int8', 'int16', ...
        'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
    
    T = blkParams.BreakpointsForDimension{1};
    dt = blk.BreakpointDataTypeStr;
    compiledDataTypesInporti = blk.CompiledPortDataTypes.Inport{1};
    
    if ismember(compiledDataTypesInporti, validDT)
        if strcmp(dt, 'Inherit: Same as corresponding input')
            blkParams.BreakpointsForDimension{1} = ...
                eval(sprintf('%s([%s])',compiledDataTypesInporti, mat2str(T)));
        elseif strcmp(dt, 'double') ...
                || strcmp(dt, 'single') ...
                || MatlabUtils.contains(dt, 'int')
            blkParams.BreakpointsForDimension{1} = ...
                eval(sprintf('%s([%s])',dt, mat2str(T)));
        end
    end
    
    if strcmp(blk.OutputSelection,'Index only')
        blkParams.OutputIndexOnly = 1;
        blkParams.directLookup = 1;
    end
    
    blkParams.ExtrapMethod = blk.ExtrapMethod;
    blkParams.InterpMethod = 'Linear';
    if strcmp(blkParams.ExtrapMethod,'Clip')
        blkParams.yIsBounded = 1;
    end
    
    blkParams.RndMeth = blk.RndMeth;
    
end

