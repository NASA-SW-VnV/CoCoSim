function [codes] = concatenateDimension2(inputs, outputs,in_matrix_dimension)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    codes = cell(1, numel(outputs));
    index = 0;
    for i=1:numel(in_matrix_dimension)       %loop over number of inports
        for j=1:numel(inputs{i})     % loop over each element of inport
            index = index + 1;
            codes{index} = nasa_toLustre.lustreAst.LustreEq(outputs{index}, inputs{i}{j});
        end
    end
end

