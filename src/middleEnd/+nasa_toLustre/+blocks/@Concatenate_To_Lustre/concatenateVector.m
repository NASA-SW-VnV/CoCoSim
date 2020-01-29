function [codes] = concatenateVector(nb_inputs, inputs, outputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    codes = cell(1, numel(outputs));
    outputIndex = 0;
    for i=1:nb_inputs
        for j=1:numel(inputs{i})
            outputIndex = outputIndex + 1;
            codes{outputIndex} = nasa_toLustre.lustreAst.LustreEq(outputs{outputIndex}, inputs{i}{j});
        end
    end
end
        

