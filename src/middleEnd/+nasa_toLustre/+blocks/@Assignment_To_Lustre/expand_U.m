function [in_matrix_dimension, U_expanded_dims,inputs] = ...
        expand_U(~, parent,blk,inputs,numOutDims)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
    U_expanded_dims = in_matrix_dimension{2};
    % if U input is a scalar and it is to be expanded, U_expanded_dims
    % needed to be calculated.
    indexPortNumber = 0;
    if numel(inputs{2}) == 1
        U_expanded_dims.numDs = numOutDims;
        U_expanded_dims.dims = ones(1,numOutDims);
        U_expanded_dims.width = 1;
        for i=1:numOutDims
            if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                U_expanded_dims.dims(i) = in_matrix_dimension{1}.dims(i);
            elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                U_expanded_dims.dims(i) = ...
                    numel(nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk,blk.IndexParamArray{i}));
            elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                indexPortNumber = indexPortNumber + 1;
                portNumber = indexPortNumber + 2;
                U_expanded_dims.dims(i) = numel(inputs{portNumber});
            elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                U_expanded_dims.dims(i) = 1;
            elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                U_expanded_dims.dims(i) = 1;
            else
            end
            U_expanded_dims.width = U_expanded_dims.width*U_expanded_dims.dims(i);
        end
    end
    
    if numel(inputs{2}) == 1 && numel(inputs{2}) < U_expanded_dims.width
        inputs{2} = arrayfun(@(x) {inputs{2}{1}}, (1:U_expanded_dims.width));
    end
end
