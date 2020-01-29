function blkParams = readBlkParams(~,parent,blk,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Lookup_nD_To_Lustre
    
    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.Lookup_nD;
    blkParams.tableIsInputPort = false;
    % read blk
    [blkParams.NumberOfTableDimensions, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
        parent, blk, blk.NumberOfTableDimensions);
    
    blkParams.DataSpecification = blk.DataSpecification;
    
    % read table and breakpoints
    blkParams = readTableAndBP(parent, blk, blkParams);
    
    
    
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
    %     blkParams.tableMin = min(blkParams.T(:));
    %     blkParams.tableMax = max(blkParams.T(:));
    blkParams.tableMin = 0.;
    blkParams.tableMax = 1.e15;
    
    
    blkParams.RndMeth = blk.RndMeth;
    blkParams.SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
    
    % calculate dimJump and boundNodeOrder
    blkParams = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addCommonData2BlkParams(...
        blkParams);
    
end

function blkParams = readTableAndBP(parent, blk, blkParams)
    
    validDT = {'double', 'single', 'int8', 'int16', ...
        'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
    if strcmp(blk.DataSpecification, 'Lookup table object')
        % read Table
        [lkObject, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.LookupTableObject);
        T = lkObject.Table.Value;
        T_dt = lkObject.Table.DataType;
        if ismember(T_dt, validDT)
            T = cast(T, T_dt);
        end
        blkParams.Table = T;
        blkParams.TableDim = ...
            nasa_toLustre.blocks.Interpolation_nD_To_Lustre.reduceDim(size(T));
        
        % read BreakPoints
        if strcmp(lkObject.BreakpointsSpecification, 'Explicit values')
            for i=1:blkParams.NumberOfTableDimensions
                B = lkObject.Breakpoints(i).Value;
                bp_dt = lkObject.Breakpoints(i).DataType;
                if ismember(bp_dt, validDT)
                    B = cast(B, bp_dt);
                end
                blkParams.BreakpointsForDimension{i} = B;
            end
            
        elseif strcmp(lkObject.BreakpointsSpecification, 'Reference')
            for i=1:blkParams.NumberOfTableDimensions
                [BObject, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.Breakpoints{i});
                B = BObject.Breakpoints.Value;
                bp_dt = BObject.Breakpoints.DataType;
                if ismember(bp_dt, validDT)
                    B = cast(B, bp_dt);
                end
                blkParams.BreakpointsForDimension{i} = B;
            end
            
        else  % 'Even spacing'
            for i=1:blkParams.NumberOfTableDimensions
                bp_dt = lkObject.Breakpoints(i).DataType;
                firstPoint = lkObject.Breakpoints(i).FirstPoint;
                spacing = lkObject.Breakpoints(i).Spacing;
                if ismember(bp_dt, validDT)
                    firstPoint = cast(firstPoint, bp_dt);
                    spacing = cast(spacing, bp_dt);
                end
                
                B = zeros(1,blkParams.TableDim(i));   %[];
                for j=1:blkParams.TableDim(i)
                    B(j) = firstPoint + (j-1)*spacing;
                end
                
                
                
                blkParams.BreakpointsForDimension{i} = B;
            end
        end
        
        
    else
        % 'Table and breakpoints'
        % cast table data
        [T, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.Table);
        
        if strcmp(blk.TableDataTypeStr, 'Inherit: Inherit from ''Table data''')
            % no casting
        elseif strcmp(blk.TableDataTypeStr, 'Inherit: Same as output')
            T_dt = blk.CompiledPortDataTypes.Outport{1};
            if ismember(T_dt, validDT)
                T = cast(T, T_dt);
            end
        elseif ismember(blk.TableDataTypeStr, validDT)
            T = cast(T, blk.TableDataTypeStr);
        end
        blkParams.Table = T;
        blkParams.TableDim = ...
            nasa_toLustre.blocks.Interpolation_nD_To_Lustre.reduceDim(size(T));
        
        % read breakpoints
        tableDims = blkParams.TableDim;
        
        for i=1:blkParams.NumberOfTableDimensions
            if strcmp(blk.BreakpointsSpecification, 'Even spacing')
                [firstPoint, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.(sprintf('BreakpointsForDimension%dFirstPoint', i)));
                [spacing, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.(sprintf('BreakpointsForDimension%dSpacing',i)));
                curBreakPoint = zeros(1, tableDims(i));   %[];
                
                for j=1:tableDims(i)
                    curBreakPoint(j) = firstPoint + (j-1)*spacing;
                end
            else % 'Explicit values'
                [curBreakPoint, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.(sprintf('BreakpointsForDimension%d',i)));
            end
            
            bp_dt = blk.(sprintf('BreakpointsForDimension%dDataTypeStr',i));
            if strcmp(bp_dt, 'Inherit: Same as corresponding input')
                if strcmp(blk.UseOneInputPortForAllInputData, 'on')
                    bp_dt = blk.CompiledPortDataTypes.Inport{1};
                else
                    bp_dt = blk.CompiledPortDataTypes.Inport{i};
                end
            end
            if ismember(bp_dt, validDT)
                curBreakPoint = cast(curBreakPoint, bp_dt);
            end
            blkParams.BreakpointsForDimension{i} = curBreakPoint;
        end
        
    end
    
    
end