classdef Product_To_Lustre < Block_To_Lustre
    %Product_To_Lustre The Product block performs addition or subtraction on its
    %inputs. This block can add or subtract scalar, vector, or matrix inputs.
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to
    %its accumulator data type, then performs the specified operations.
    %The block converts the result to its output data type using the
    %specified rounding and overflow modes.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            isSumBlock = false;
            [codes, outputs_dt, additionalVars] = Sum_To_Lustre.getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock, OutputDataTypeStr);
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, blk, varargin)
            % add your unsuported options list here
            if strcmp(blk.Multiplication, 'Matrix(*)')...
                    && contains(blk.Inputs, '/')
                obj.addUnsupported_options(...
                    sprintf('Option Matrix(*) with divid is not supported in block %s', ...
                    blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        % This method assume there are at least 2 inputs.
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
                    if numDs == 1
                        % fix the case where it is a vector, [1 x] where x
                        % is the number of elements in the vector, we
                        % should change the [1 x] to [2 1 x] or [2 x 1]
                        % depending on the product.
                        if i==1
                            if inport_dimensions(i+2) == 1
                                in_matrix_dimension{numMat}.dims(1,1) = 1;
                                in_matrix_dimension{numMat}.dims(1,2) = inport_dimensions(i);
                            else
                                in_matrix_dimension{numMat}.dims(1,1) = inport_dimensions(i);
                                in_matrix_dimension{numMat}.dims(1,2) = 1;
                            end
                        else
                            if in_matrix_dimension{numMat-1}.dims(1,end) == 1
                                in_matrix_dimension{numMat}.dims(1,1) = 1;
                                in_matrix_dimension{numMat}.dims(1,2) = inport_dimensions(i);
                            else
                                in_matrix_dimension{numMat}.dims(1,1) = inport_dimensions(i);
                                in_matrix_dimension{numMat}.dims(1,2) = 1;
                            end
                            
                        end
                    else
                        in_matrix_dimension{numMat}.dims(1,index) = inport_dimensions(i);
                    end
                    if index == numDs;
                        readMatrixDimension = true;
                    end
                end
                
            end
        end
        
        function [codes, product_out, addVars] = matrix_multiply(m1_dim, m2_dim, ...
                input_m1, input_m2, output_m, zero, pair_number, OutputDT, tmp_prefix)
            codeIndex = 0;
            initCode = sprintf('%s ',zero);
            m=m1_dim.dims(1,1);
            n=m1_dim.dims(1,2);
            l=m2_dim.dims(1,2);
            addVars = {};
            if numel(output_m) == 0
                index = 0;
                for i=1:m
                    for j=1:l
                        index = index+1;
                        product_out{index} = sprintf('%s_matrix_mult_%d_%d',tmp_prefix, pair_number,index);
                        addVars{index} = sprintf('%s:%s;',...
                            product_out{index}, OutputDT);
                    end
                end
            else
                product_out = output_m;
            end
            for i=1:m      %i is row of result matrix
                for j=1:l      %j is column of result matrix
                    codeIndex = codeIndex + 1;
                    code = initCode;
                    for k=1:n
                        aIndex = (i-1)*n+k;
                        bIndex = (k-1)*l+j;
                        code = sprintf('%s + (%s * %s)',code, input_m1{1,aIndex},input_m2{1,bIndex});
                        
                        diag = sprintf('i %d, j %d, k %d, aIndex %d, bIndex %d',i,j,k,aIndex,bIndex);
                    end
                    
                    codes{codeIndex} = sprintf('%s = %s;\n\t', product_out{codeIndex}, code) ;
                end
                
            end
        end
        
    end
    
end

