function blkParams = readBlkParams(~,parent,blk,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_nD_To_Lustre
    
    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.Interpolation_nD;
    
    % read blk
    blkParams.NumberOfTableDimensions = str2num(blk.NumberOfTableDimensions);
    blkParams.RequireIndexFractionAsBus = blk.RequireIndexFractionAsBus;
    
    blkParams.tableIsInputPort =  strcmp(blk.TableSpecification, 'Explicit values') ...
        && strcmp(blk.TableSource, 'Input port');
    
    blkParams.TableSource = blk.TableSource;
    blkParams.TableSpecification = blk.TableSpecification;
    
    % read table
    if strcmp(blk.TableSpecification, 'Lookup table object')
        %lkObject = evalin('base', blk.LookupTableObject);
        [lkObject, ~, ~] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
            parent, blk, blk.LookupTableObject);
        T = lkObject.Table.Value;
        T_dt = lkObject.Table.DataType;
        if strcmp(T_dt, 'auto')
            T_dt = 'Inherit: Inherit from ''Table data''';
        end
        blkParams.TableDim = size(T);
    else
        %'Explicit values'
        if strcmp(blk.TableSource, 'Dialog')
            [T, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
                parent, blk, blk.Table);
            T_dt = blk.TableDataTypeStr;
            blkParams.TableDim = size(T);
        else
            % input port
            TableWidth = blk.CompiledPortWidths.Inport(end);
            T = cell(1, TableWidth);
            for i=1:TableWidth
                T{i} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('ydat_%d', i));
            end
            in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            blkParams.TableDim = in_matrix_dimension{end}.dims;
        end
    end
    if blkParams.TableDim(1) == 1 && length(blkParams.TableDim) > 1
        blkParams.TableDim = blkParams.TableDim(2:end);
    end
    if blkParams.TableDim(end) == 1 && length(blkParams.TableDim) > 1
        blkParams.TableDim = blkParams.TableDim(1:end-1);
    end
    % cast table
    if ~ blkParams.tableIsInputPort
            % cast table data
            validDT = {'double', 'single', 'int8', 'int16', ...
                'int32', 'uint8', 'uint16', 'uint32', 'boolean'};
            if strcmp(T_dt, 'Inherit: Inherit from ''Table data''')
                % no casting
            elseif strcmp(T_dt, 'Inherit: Same as output')
                if ismember(blk.CompiledPortDataTypes.Outport{1}, validDT)
                    T = cast(T, blk.CompiledPortDataTypes.Outport{1});
                end
            elseif strcmp(T_dt, 'double') ...
                    || strcmp(T_dt, 'single') ...
                    || MatlabUtils.contains(T_dt, 'int')
                T = cast(T, T_dt);
            end
    end
    blkParams.Table = T;
    
    blkParams.InterpMethod = blk.InterpMethod;
    blkParams.ExtrapMethod = blk.ExtrapMethod;
    blkParams.directLookup = false;
    blkParams.yIsBounded = false;
    if strcmp(blkParams.InterpMethod,'Flat') || strcmp(blkParams.InterpMethod,'Nearest')
        blkParams.directLookup = true;
        blkParams.yIsBounded = true;
    end
    if strcmp(blkParams.ExtrapMethod,'Clip')
        blkParams.yIsBounded = true;
    end
    
    blkParams.NumSelectionDims = blk.NumSelectionDims;
    [blkParams.NumSelectionDims, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(...
        parent, blk, blk.NumSelectionDims);
    
    blkParams.RndMeth = blk.RndMeth;
    blkParams.SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
    
    % tableMin, tableMax for contract
    if ~ blkParams.tableIsInputPort
        blkParams.tableMin = min(blkParams.Table(:));
        blkParams.tableMax = max(blkParams.Table(:));
    else
        blkParams.tableMin = [];
        blkParams.tableMax = [];
    end
    
    blkParams.ValidIndexMayReachLast = 'off';
    if ~(strcmp(blkParams.InterpMethod,'Linear') && strcmp(blkParams.ExtrapMethod,'Linear'))
        blkParams.ValidIndexMayReachLast = blk.ValidIndexMayReachLast;
    end
    
    % calculate dimJump and boundNodeOrder
    blkParams = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addCommonData2BlkParams(...
        blkParams);
    
end

