%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blkParams = readBlkParams(~,parent,blk,blkParams)

%    % Interpolation_nD_To_Lustre
    
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
                    || coco_nasa_utils.MatlabUtils.contains(T_dt, 'int')
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

