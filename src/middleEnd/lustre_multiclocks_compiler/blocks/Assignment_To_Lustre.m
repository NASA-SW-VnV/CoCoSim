classdef Assignment_To_Lustre < Block_To_Lustre
    % Assignment_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            %             OutputInitialize = blk.OutputInitialize;
            IndexMode = blk.IndexMode;
            [NumberOfDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
            %             IndexOptions = blk.IndexOptions;
            %             [Indices, ~, ~] = ...
            %                 Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Indices);
            %             OutputSizes = blk.OutputSizes;
            codes = {};
            %if isempty(find(~strcmp(blk.IndexOptionArray, 'Index vector (dialog)'), 1))
            
            
            in_matrix_dimension = Reshape_To_Lustre.getInputMatrixDimensions(blk);
            if in_matrix_dimension{1}.numDs == 1
                numColY0 = in_matrix_dimension{1}.dims(1);
                onDimension = true;
            else
                onDimension = false;
                numColY0 = in_matrix_dimension{1}.dims(2);
            end
            if in_matrix_dimension{2}.numDs == 1
                numRowU = 1;
                numColU = in_matrix_dimension{2}.dims(1);
            else
                numRowU = in_matrix_dimension{2}.dims(1);
                numColU = in_matrix_dimension{2}.dims(2);
            end
            
            indexPortNumber = 0;
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                    if i==1
                        ind{i} = (1:numRowU);
                    else
                        ind{i} = (1:numColU);
                    end
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    ind{i} = Idx;
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U
                    indexBlock = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
                    [ind{i}, ~, status] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, indexBlock, indexBlock.Value);
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    if i==1
                        ind{i} = (Idx:Idx+numRowU-1);
                    else
                        ind{i} = (Idx:Idx+numColU-1);
                    end
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U
                    indexBlock = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
                    [startIndex, ~, status] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, indexBlock, indexBlock.Value);
                    if i==1
                        ind{i} = (startIndex:startIndex+numRowU-1);
                    else
                        ind{i} = (startIndex:startIndex+numColU-1);
                    end
                else
                    % should not be here
                    display_msg(sprintf('IndexOption  %s not recognized in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Assignment_To_Lustre', '');
                end
            end
                                
            % hard code for 2D.  do recursive call for n dims later
            indexToBeAssigned = [];
            codeIndex = 0;
            if onDimension
                for colU=1:numColU
                    out_j = ind{1}(colU);
                    outIndex =  out_j;
                    Uindex =  colU;
                    indexToBeAssigned = [indexToBeAssigned, outIndex];
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{outIndex}, inputs{2}{Uindex});
                end
            else
                for rowU=1:numRowU
                    for colU=1:numColU
                        out_i = ind{1}(rowU);
                        out_j = ind{2}(colU);
                        outIndex = (out_i-1)*numColY0 + out_j;
                        Uindex = (rowU-1)*numColU + colU;
                        indexToBeAssigned = [indexToBeAssigned, outIndex];
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{outIndex}, inputs{2}{Uindex});
                    end
                end
            end
            
            % write unassigned element
            for i=1:numel(outputs)
                if ~ismember(i,indexToBeAssigned)
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{1}{i});
                end
            end
                        
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            
            options = obj.unsupported_options;
        end
    end
    
    
    methods(Static)
        % This method allows for only 1 input, the same static under
        % Product_To_Lustre may require more than 1 input
        function in_matrix_dimension = getInputMatrixDimensions(blk)
            % return structure of matrix size
            in_matrix_dimension = {};
            readMatrixDimension = true;
            numMat = 0;
            inport_dimensions = blk.CompiledPortDimensions.Inport;
            
            for i=1:numel(inport_dimensions)
                if readMatrixDimension
                    numMat = numMat + 1;
                    numDs = inport_dimensions(i);
                    readMatrixDimension = false;
                    in_matrix_dimension{numMat}.numDs = numDs;
                    in_matrix_dimension{numMat}.dims = zeros(1,numDs);
                    index = 0;
                else
                    index = index + 1;
                    in_matrix_dimension{numMat}.dims(1,index) = inport_dimensions(i);
                    if index == numDs;
                        readMatrixDimension = true;
                    end
                end
                
            end
        end
        
    end
    
    
    
end

