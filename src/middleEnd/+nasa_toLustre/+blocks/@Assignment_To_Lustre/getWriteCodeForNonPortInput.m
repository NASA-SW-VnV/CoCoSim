function [codes] = getWriteCodeForNonPortInput(~, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Second approach
    in_matrix_dimension_1_dims = in_matrix_dimension{1}.dims;
    in_matrix_dimension_2_dims = in_matrix_dimension{2}.dims;
    if numel(in_matrix_dimension_1_dims) == 1
        in_matrix_dimension_1_dims = [1, in_matrix_dimension_1_dims];
    end
    if numel(in_matrix_dimension_2_dims) == 1
        in_matrix_dimension_2_dims = [1, in_matrix_dimension_2_dims];
    end    
    Y0_reshaped = reshape(inputs{1}, in_matrix_dimension_1_dims);
    U_reshaped = reshape(inputs{2}, in_matrix_dimension_2_dims);
    Y = Y0_reshaped;
    Y(ind{:}) = U_reshaped;
    Y_inlined = reshape(Y, [1, prod(in_matrix_dimension{1}.dims)]);
    for i=1:numel(outputs)
        codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, Y_inlined{i});
    end
end
