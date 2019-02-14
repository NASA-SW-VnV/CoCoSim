function [blkParams,in_matrix_dimension] = readBlkParams(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    blkParams = struct;
    blkParams.isVector = strcmp(blk.Mode,'Vector');
    in_matrix_dimension = ...
        Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
    % Users may specified Multidimensional array but define vector
    % for inputs.  This case is equivalent to Vector.
    if ~blkParams.isVector
        if in_matrix_dimension{1}.numDs == 1
            blkParams.isVector = 1;
        end
    end
end
