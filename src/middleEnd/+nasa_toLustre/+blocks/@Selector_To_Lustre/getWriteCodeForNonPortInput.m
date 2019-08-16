function [codes] = getWriteCodeForNonPortInput(~, numOutDims,...
        inputs,outputs,ind,outputDimsArray,...
        in_matrix_dimension) % do not remove in_matrix_dimension parameter
                            % It is used in eveal function.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialization
    
    codes = {};

    in_matrix_dimension_1_dims = in_matrix_dimension{1}.dims;
    if numel(in_matrix_dimension_1_dims) == 1
        in_matrix_dimension_1_dims = [1, in_matrix_dimension_1_dims];
    end
    U_reshaped = reshape(inputs{1}, in_matrix_dimension_1_dims);
    Y = U_reshaped(ind{:});
    Y_inlined = reshape(Y, [1, numel(Y)]);
    for i=1:numel(outputs)
        codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, Y_inlined{i});
    end
end
