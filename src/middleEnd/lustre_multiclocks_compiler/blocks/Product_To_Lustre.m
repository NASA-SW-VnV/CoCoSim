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
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            isSumBlock = false;
            [codes, outputs_dt, additionalVars] = ...
                Sum_To_Lustre.getSumProductCodes(obj, parent, blk, ...
                OutputDataTypeStr,isSumBlock, OutputDataTypeStr, xml_trace);
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % add your unsuported options list here
            if strcmp(blk.Multiplication, 'Matrix(*)')...
                    && contains(blk.Inputs, '/')
                obj.addUnsupported_options(...
                    sprintf('Option Matrix(*) with divid is not supported in block %s', ...
                    blk.Origin_path));
            end
            % if there is one input and the output dimension is > 7
            if numel(blk.CompiledPortWidths.Inport) == 1 ...
                    &&  numel(blk.CompiledPortDimensions.Outport) > 7
                obj.addUnsupported_options(...
                    sprintf('Dimension %s in block %s is not supported.',...
                    mat2str(blk.CompiledPortDimensions.Inport), blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        function [codes, AdditionalVars] = matrix_multiply(blk, inputs, outputs, zero, LusOutputDataTypeStr )
            % check that the number of columns of 1st input matrix is equalled
            % to the number of rows of the 2nd matrix
            % matrix C(mxl) = A(mxn)*B(nxl)
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            % the index of the current matrix pair
            pair_number = 0;
            codes = {};
            AdditionalVars = {};
            productOutputs = {};
            tmp_prefix = SLX2LusUtils.node_name_format(blk);
            for i=1:numel(in_matrix_dimension)-1
                pair_number = pair_number + 1;
                output_m = {};
                m2_dimension = in_matrix_dimension{i+1};
                if i==1
                    m1_inputs = inputs{1};
                    m1_dimension = in_matrix_dimension{i};
                else
                    m1_inputs = productOutputs;
                    m1_dim.dims(1,1) = in_matrix_dimension{1}.dims(1,1);
                    m1_dim.dims(1,2) = in_matrix_dimension{i}.dims(1,2);
                    m1_dimension = m1_dim;
                end
                if i==numel(in_matrix_dimension)-1
                    output_m = outputs;
                end
                
                [code, productOutputs, addVar] = Product_To_Lustre.matrix_multiply_pair(m1_dimension, ...
                    m2_dimension, m1_inputs,...
                    inputs{i+1}, output_m, zero, pair_number, LusOutputDataTypeStr, tmp_prefix);
                codes = [codes, code];
                %productOutputs = [productOutputs, tmp_outputs];
                AdditionalVars = [AdditionalVars, addVar];
            end
        end
        function [codes, product_out, addVars] = matrix_multiply_pair(m1_dim, m2_dim, ...
                input_m1, input_m2, output_m, zero, pair_number, OutputDT, tmp_prefix)
            % adding additional variables for inside matrices.  For
            % AxBxCxD, B and C are inside matrices and needs additional
            % variables
            codeIndex = 0;
            initCode = sprintf('%s ',zero);
            m=m1_dim.dims(1,1);
            if numel(m1_dim.dims) > 1
                n=m1_dim.dims(1,2);
            else
                n = 1;
            end
            if numel(m2_dim.dims) > 1
                l=m2_dim.dims(1,2);
            else
                l = 1;
            end
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
            % doing matrix multiplication, A = BxC
            for i=1:m      %i is row of result matrix
                for j=1:l      %j is column of result matrix
                    codeIndex = codeIndex + 1;
                    code = initCode;
                    for k=1:n
                        aIndex = sub2ind([m,n],i,k);
                        bIndex = sub2ind([n,l],k,j);
                        code = sprintf('%s + (%s * %s)',code, input_m1{1,aIndex},input_m2{1,bIndex});
                        %                         diag = sprintf('i %d, j %d, k %d, aIndex %d, bIndex %d',i,j,k,aIndex,bIndex);
                    end
                    productOutIndex = sub2ind([m,l],i,j);
                    codes{codeIndex} = sprintf('%s = %s;\n\t', product_out{productOutIndex}, code) ;
                end
                
            end
        end
        
    end
    
end

