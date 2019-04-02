function blkParams = readBlkParams(~,parent,blk,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD_To_Lustre

    blkParams.lookupTableType = LookupType.Lookup_nD;

    if strcmp(blk.DataSpecification, 'Lookup table object')
        display_msg(sprintf('Lookup table object for DataSpecification in block %s is not supported',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
    end

    % read blk
    [blkParams.NumberOfTableDimensions, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
        parent, blk, blk.NumberOfTableDimensions);
    % cast table data
    [T, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
        parent, blk, blk.Table);
    validDT = {'double', 'single', 'int8', 'int16', ...
        'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
    if ismember(blk.CompiledPortDataTypes.Outport{1}, validDT)
        if isequal(blk.TableDataTypeStr, 'Inherit: Same as output')
            % don't cast if double or single and
            % dimensions 3 and above working
            if blkParams.NumberOfTableDimensions >=  3
                blkParams.Table = T;
            else
                blkParams.Table = eval(sprintf('%s([%s])',...
                    blk.CompiledPortDataTypes.Outport{1}, mat2str(T)));
            end
        elseif isequal(blk.TableDataTypeStr, 'double') ...
                || isequal(blk.TableDataTypeStr, 'single') ...
                || MatlabUtils.contains(blk.TableDataTypeStr, 'int')
            blkParams.Table = eval(sprintf('%s([%s])',...
                blk.TableDataTypeStr, mat2str(T)));
        else
            blkParams.Table = T;
        end
    else
        blkParams.Table = T;
    end
    % AdjustedTable and NumberOfAdjustedTableDimensions are used in the 
    % shared code between Lookup_nD and Interpolation_nD. For Lookup_nD,
    % there is no adjustment.
    blkParams.NumberOfAdjustedTableDimensions = blkParams.NumberOfTableDimensions;
    % read breakpoints
    tableDims = size(blkParams.Table);
    if strcmp(blk.BreakpointsSpecification, 'Even spacing')
        for i=1:blkParams.NumberOfTableDimensions
            [firstPoint, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, blk.(sprintf('BreakpointsForDimension%dFirstPoint', i)));
            [spacing, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, blk.(sprintf('BreakpointsForDimension%dSpacing',i)));
            curBreakPoint = [];
            
            for j=1:tableDims(i)
                curBreakPoint(j) = firstPoint + (j-1)*spacing;
            end
            blkParams.BreakpointsForDimension{i} = curBreakPoint;
        end
    else
        for i=1:blkParams.NumberOfTableDimensions

            [blkParams.BreakpointsForDimension{i}, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, blk.(sprintf('BreakpointsForDimension%d',i)));
        end
    end
    %cast breakpoints
    for i=1:blkParams.NumberOfTableDimensions
        T = blkParams.BreakpointsForDimension{i};
        dt = blk.(strcat('BreakpointsForDimension',num2str(i), 'DataTypeStr'));
        % only 1 Inport if "Use one input port for all input
        % data"
        compiledDataTypesInporti = blk.CompiledPortDataTypes.Inport{1};
        if ~strcmp(blk.UseOneInputPortForAllInputData, 'on')
            compiledDataTypesInporti = blk.CompiledPortDataTypes.Inport{i};
        end
        if ismember(compiledDataTypesInporti, validDT)
            if isequal(dt, 'Inherit: Same as corresponding input')
                blkParams.BreakpointsForDimension{i} = eval(sprintf('%s([%s])',compiledDataTypesInporti, mat2str(T)));
                %blkParams.BreakpointsForDimension{i} = sprintf('%s([%s])',compiledDataTypesInporti, mat2str(T));
            elseif isequal(dt, 'double') ...
                    || isequal(dt, 'single') ...
                    || MatlabUtils.contains(dt, 'int')
                blkParams.BreakpointsForDimension{i} = eval(sprintf('%s([%s])',dt, mat2str(T)));
            end
        end
    end
    blkParams.InterpMethod = blk.InterpMethod;
    blkParams.ExtrapMethod = blk.ExtrapMethod;
    blkParams.directLookup = 0;
    if strcmp(blkParams.InterpMethod,'Flat') || strcmp(blkParams.InterpMethod,'Nearest')
        blkParams.directLookup = 1;
        blkParams.yIsBounded = 1;
    end
    if strcmp(blkParams.ExtrapMethod,'Clip')
        blkParams.yIsBounded = 1;
    end
    
    % tableMin and tableMax may be used for contract
    blkParams.tableMin = min(blkParams.Table(:));
    blkParams.tableMax = max(blkParams.Table(:));
    
    blkParams.RndMeth = blk.RndMeth;
    blkParams.SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;

end

