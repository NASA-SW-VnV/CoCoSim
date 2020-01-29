function blkParams = readBlkParams(~,parent,blk,blkParams, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % PreLookup_To_Lustre
    
    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.PreLookup;
    blkParams.OutputIndexOnly = 0;
    
    % read blk
    blkParams.NumberOfTableDimensions = 1;
    blkParams.NumberOfTableDimensions = 1;
    % read blk
    % read breakpoints
    bpIsInputPort = false;
    if strcmp(blk.BreakpointsSpecification, 'Breakpoint object')
        try
            %bpObject = evalin('base', blk.BreakpointObject);
            [bpObject, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.BreakpointObject);
            [blkParams.BreakpointsForDimension{1}, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, bpObject.Breakpoints.Value);
            bdObject_dt = bpObject.Breakpoints.DataType;
            if strcmp(bdObject_dt, 'auto')
                bdObject_dt = 'Inherit: Inherit from ''Breakpoint data''';
            end
        catch
            display_msg(sprintf('Breakpoint object for BreakpointsSpecification in block %s is not supported',...
                HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'PreLookup_To_Lustre', '');
            bdObject_dt = 'Inherit: Inherit from ''Breakpoint data''';
        end
        
    elseif strcmp(blk.BreakpointsSpecification, 'Even spacing')
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
        % Explicit values
        if strcmp(blk.BreakpointsDataSource, 'Input port')
            blkParams.BreakpointsForDimension{1} = inputs{2};
            bpIsInputPort = true;
        else
            [blkParams.BreakpointsForDimension{1}, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, blk.BreakpointsData);
        end
    end
    blkParams.bpIsInputPort = bpIsInputPort;
    
    %cast breakpoints
    validDT = {'double', 'single', 'int8', 'int16', ...
        'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
    
    
    T = blkParams.BreakpointsForDimension{1};% Don't remove: it's used in eval function
    if strcmp(blk.BreakpointsSpecification, 'Breakpoint object')
        bp_dt = bdObject_dt;
    else
        bp_dt = blk.BreakpointDataTypeStr;
    end
    compiledDataTypesInporti = blk.CompiledPortDataTypes.Inport{1};
    if bpIsInputPort
        % T is inputs{1} and not numerical values
        % No casting is needed
    else
        % T is numerical
        
        if strcmp(bp_dt, 'Inherit: Inherit from ''Breakpoint data''')
            % No need for casting.
        elseif strcmp(bp_dt, 'Inherit: Same as corresponding input')
            if ismember(compiledDataTypesInporti, validDT)
                blkParams.BreakpointsForDimension{1} = ...
                    cast(T, compiledDataTypesInporti);
            end
        elseif strcmp(bp_dt, 'double') ...
                || strcmp(bp_dt, 'single') ...
                || (MatlabUtils.contains(bp_dt, 'int') && numel(bp_dt) <= 6)
            blkParams.BreakpointsForDimension{1} = ...
                cast(T, bp_dt);
        end
        
    end
    
    blkParams.OutputSelection = blk.OutputSelection;
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
    blkParams.UseLastBreakpoint = 'off';
    if strcmp(blk.ExtrapMethod, 'Clip') 
        if strcmp(blk.OutputSelection,'Index only')
            blkParams.UseLastBreakpoint = 'on';
        else
            blkParams.UseLastBreakpoint = blk.UseLastBreakpoint;
        end
    end
    
    
    % calculate dimJump and boundNodeOrder
    blkParams = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addCommonData2BlkParams(...
        blkParams);
    
end

