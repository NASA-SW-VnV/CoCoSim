function blkParams = readBlkParams(~,parent,blk,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD_To_Lustre

    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.Lookup_nD;

    % read blk
    [blkParams.NumberOfTableDimensions, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
        parent, blk, blk.NumberOfTableDimensions);
    
    blkParams.DataSpecification = blk.DataSpecification;
    
    % read table
    if strcmp(blk.DataSpecification, 'Lookup table object')
        lkObject = evalin('base', blk.LookupTableObject);
        T = lkObject.Table.Value;
        T_dt = lkObject.Table.DataType;
        if strcmp(T_dt, 'auto')
            T_dt = 'Inherit: Inherit from ''Table data''';
        end
        blkParams.TableDim = size(T);
        
        if strcmp(lkObject.BreakpointsSpecification, 'Explicit values')
            

            try
                for i=1:blkParams.NumberOfTableDimensions
                    blkParams.BreakpointsForDimension{i} = ...
                        lkObject.Breakpoints(i).Value;
                end

                bdObject_dt = lkObject.Breakpoints.DataType;
                if strcmp(bdObject_dt, 'auto')
                    bdObject_dt = 'Inherit: Inherit from ''Breakpoint data''';
                end
            catch
                display_msg(sprintf('Breakpoint object for BreakpointsSpecification in block %s is not supported',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'PreLookup_To_Lustre', '');
                bdObject_dt = 'Inherit: Inherit from ''Breakpoint data''';
            end             

            
        elseif strcmp(lkObject.BreakpointsSpecification, 'Reference')
            
        else  % 'Even spacing'
            
        end
        
        blkParams.Table = T;
    else
        % 'Table and breakpoints'
        % cast table data
        [T, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.Table);
        validDT = {'double', 'single', 'int8', 'int16', ...
            'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
        if ismember(blk.CompiledPortDataTypes.Outport{1}, validDT)
            if strcmp(blk.TableDataTypeStr, 'Inherit: Same as output')
                % don't cast if double or single and
                % dimensions 3 and above working
                if blkParams.NumberOfTableDimensions >=  3
                    blkParams.Table = T;
                else
                    blkParams.Table = eval(sprintf('%s([%s])',...
                        blk.CompiledPortDataTypes.Outport{1}, mat2str(T)));
                end
            elseif strcmp(blk.TableDataTypeStr, 'double') ...
                    || strcmp(blk.TableDataTypeStr, 'single') ...
                    || MatlabUtils.contains(blk.TableDataTypeStr, 'int')
                blkParams.Table = eval(sprintf('%s([%s])',...
                    blk.TableDataTypeStr, mat2str(T)));
            else
                blkParams.Table = T;
            end
        else
            blkParams.Table = T;
        end
        blkParams.TableDim = size(T);

        % read breakpoints
        tableDims = blkParams.TableDim;
        if strcmp(blk.BreakpointsSpecification, 'Even spacing')
            for i=1:blkParams.NumberOfTableDimensions
                [firstPoint, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.(sprintf('BreakpointsForDimension%dFirstPoint', i)));
                [spacing, ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                    parent, blk, blk.(sprintf('BreakpointsForDimension%dSpacing',i)));
                curBreakPoint = zeros(tableDims(i));   %[];
                
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
                if strcmp(dt, 'Inherit: Same as corresponding input')
                    blkParams.BreakpointsForDimension{i} = eval(sprintf('%s([%s])',compiledDataTypesInporti, mat2str(T)));
                    %blkParams.BreakpointsForDimension{i} = sprintf('%s([%s])',compiledDataTypesInporti, mat2str(T));
                elseif strcmp(dt, 'double') ...
                        || strcmp(dt, 'single') ...
                        || MatlabUtils.contains(dt, 'int')
                    %blkParams.BreakpointsForDimension{i} = eval(sprintf('%s([%s])',dt, mat2str(T)));
                end
            end
        end
        
        
    end
    
    if blkParams.TableDim(1) == 1 && length(blkParams.TableDim) > 1
        blkParams.TableDim = blkParams.TableDim(2:end);
    end
    if blkParams.TableDim(end) == 1 && length(blkParams.TableDim) > 1
        blkParams.TableDim = blkParams.TableDim(1:end-1);
    end   


    %blkParams.numberTableData = size(T);

 

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

