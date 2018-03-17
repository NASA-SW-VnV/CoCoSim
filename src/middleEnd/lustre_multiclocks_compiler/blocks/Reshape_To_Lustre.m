classdef Reshape_To_Lustre < Block_To_Lustre
    % Reshape_To_Lustre
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
                       
            outputDimensionality = blk.OutputDimensionality;   % 1D array, row vector, column vector, customize, deriveInputPort
            dimensionType = 1;    % 1D array, row vector, and column vector
            outputDimensions = blk.OutputDimensions;
            if strcmp(blk.OutputDimensionality, 'Customize')
                dimensionType = 2;    % 2 for Customize and use outputDimensions
            elseif strcmp(blk.OutputDimensionality, 'Derive from reference input port')
                dimensionType = 3;
            end
            
            in_matrix_dimension = Reshape_To_Lustre.getInputMatrixDimensions(blk);
            codes = {}; 
            if dimensionType == 1 || dimensionType == 2 || dimensionType == 3

                % in matrix = nxm (i_in,j_in)        out matrix = kxl (i_out, j_out)
                n = in_matrix_dimension{1}.dims(1,1);                
                if in_matrix_dimension{1}.numDs==1
                    m = 1;
                elseif in_matrix_dimension{1}.numDs==2
                    m = in_matrix_dimension{1}.dims(1,2)
                else
                    display_msg(sprintf('3 or more dimensions matrix is not supported in block %s',...
                        blk.Origin_path), MsgType.WARNING, 'Reshape_To_Lustre', '');
                end
                if dimensionType == 1
                    k = numel(outputs);
                    l = 1;
                else
                    outmat_size = str2num(blk.OutputDimensions)
                    k = outmat_size(1);
                    l = outmat_size(2);
                end
                for i=1:numel(outputs)
                    i_in = rem(i,n);
                    j_in = fix(i/n)+1;
                    if rem(i,n) == 0
                        i_in = n;
                        j_in = j_in - 1;
                    end
                    inIndex = (i_in-1)*m + j_in;
                    i_out = rem(i,k);
                    j_out = fix(i/k)+1;
                    if rem(i,k) == 0
                        i_out = k;
                        j_out = j_out - 1;
                    end
                    outIndex = (i_out-1)*l + j_out;
                    sprintf('i %d, inIndex %d, outIndex %d, i_in %d, j_in %d, i_out %d, j_out %d \n\t',i, inIndex, outIndex, i_in, j_in, i_out, j_out)
                    codes{i} = sprintf('%s = %s;\n\t', outputs{outIndex}, inputs{1}{inIndex});
                end
                
            else
                display_msg(sprintf('Unknown Output dimensionality in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Reshape_To_Lustre', '');
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

