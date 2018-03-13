classdef Concatenate_To_Lustre < Block_To_Lustre
    % Concatenate_To_Lustre
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
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
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
                       
            isVector = strcmp(blk.Mode,'Vector');
            codes = {}; 
            if isVector
                outputIndex = 0;
                for i=1:numel(widths)
                    for j=1:numel(inputs{i})
                        outputIndex = outputIndex + 1;
                        codes{outputIndex} = sprintf('%s = %s;\n\t', outputs{outputIndex}, inputs{i}{j});
                    end
                end
            else
                in_matrix_dimension = Product_To_Lustre.getInputMatrixDimensions(blk);
                if strcmp(blk.ConcatenateDimension, '1')
                    index = 0;
                    for i=1:numel(in_matrix_dimension)       %loop over number of inports
                        origColLen = in_matrix_dimension{i}.dims(1);
                        for j=1:in_matrix_dimension{i}.dims(1);     % loop over each inport array 1st dimension
                            for k=1:in_matrix_dimension{i}.dims(2)                            % loop over each inport array 2nd  dimension, vector is also treated as 2Ds
                                index = index + 1;
                                inputIndex = origColLen*(j-1)+k
                                codes{index} = sprintf('%s = %s;\n\t', outputs{index}, inputs{i}{inputIndex})
                            end
                        end
                    end
                else
                    outputIndex = 0;
                    origRowLen = round(in_matrix_dimension{1}.dims(1));
                    origColLen = round(in_matrix_dimension{1}.dims(2));
                    matrixSize = round(origRowLen*origRowLen);
                    numOutputRows = origRowLen;
                    numOutputColumns = numel(in_matrix_dimension)*origColLen;
                    for i=1:numOutputRows       %loop over number of inports
                        for j=1:numOutputColumns    % loop over each inport array 1st dimension
                            outputIndex = outputIndex + 1;
                            inputPortIndex = floor((j-1)/origColLen)+ 1;
                            rowIndex = i;
                            columnIndex = rem(j,origColLen);
                            if columnIndex==0
                                columnIndex = origColLen;
                            end
                            a = sprintf('out %d, in mat %d, row %d, col %d',outputIndex, inputPortIndex, rowIndex, columnIndex)
                            inputIndex = (rowIndex-1)*origColLen + columnIndex;
                            codes{outputIndex} = sprintf('%s = %s;\n\t', outputs{outputIndex}, inputs{inputPortIndex}{inputIndex});
                        end
                    end
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
    
end

