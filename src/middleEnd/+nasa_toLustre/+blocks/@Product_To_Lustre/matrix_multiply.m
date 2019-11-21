function [codes, AdditionalVars] = matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format, operandsDT )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % check that the number of columns of 1st input matrix is equalled
    % to the number of rows of the 2nd matrix
    % matrix C(mxl) = A(mxn)*B(nxl)
    in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
    % the index of the current matrix pair
    pair_number = 0;
    codes = {};
    %AdditionalVars = {};
    productOutputs = {};
    tmp_prefix =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    [new_inputs, invertCodes, AdditionalVars] = nasa_toLustre.blocks.Product_To_Lustre.invertInputs(obj, exp, inputs, blk, LusOutputDataTypeStr);
    codes = [codes, invertCodes];
    for i=1:numel(in_matrix_dimension)-1
        pair_number = pair_number + 1;
        output_m = {};
        m2_dimension = in_matrix_dimension{i+1};
        if i==1
            m1_inputs = new_inputs{1};
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

        [code, productOutputs, addVar] = nasa_toLustre.blocks.Product_To_Lustre.matrix_multiply_pair(m1_dimension, ...
            m2_dimension, m1_inputs,...
            new_inputs{i+1}, output_m, zero, pair_number,...
            LusOutputDataTypeStr, tmp_prefix, conv_format, operandsDT);
        codes = [codes, code];
        %productOutputs = [productOutputs, tmp_outputs];
        AdditionalVars = [AdditionalVars, addVar];
    end
end
