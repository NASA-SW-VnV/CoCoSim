function in_matrix_dimension = getInputMatrixDimensions(inport_dimensions)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    if inport_dimensions(1) == -2
        % bus case, the first 2 elements should be ignored
        inport_dimensions = inport_dimensions(3:end);
    end
    % return structure of matrix size
    in_matrix_dimension = {};
    readMatrixDimension = true;
    numMat = 0;
    i = 1;
    while i <= numel(inport_dimensions)
        if readMatrixDimension
            numMat = numMat + 1;
            if inport_dimensions(i) == -2
                % bus signal: skip 2 scalars
                i = i + 2;
            end
            numDs = inport_dimensions(i);
            
            readMatrixDimension = false;
            in_matrix_dimension{numMat}.numDs = numDs;
            in_matrix_dimension{numMat}.dims = zeros(1,numDs);
            index = 0;
        else
            index = index + 1;
            in_matrix_dimension{numMat}.dims(1,index) = inport_dimensions(i);
            if index == numDs
                readMatrixDimension = true;
            end
        end
        i = i + 1;
    end
    
    % add width information
    for i=1:numel(in_matrix_dimension)
        in_matrix_dimension{i}.width = prod(in_matrix_dimension{i}.dims);
    end
end