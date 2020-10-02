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
    if isfield(blkParams, 'Table') && isnumeric(blkParams.Table)
        blkParams.tableMin = min(blkParams.Table(:));
        blkParams.tableMax = max(blkParams.Table(:));
    else
        blkParams.tableMin = [];
        blkParams.tableMax = [];
    end
    
    
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