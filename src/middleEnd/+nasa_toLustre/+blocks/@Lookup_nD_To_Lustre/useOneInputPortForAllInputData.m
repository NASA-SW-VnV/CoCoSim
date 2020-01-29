function inputs = useOneInputPortForAllInputData(blk,inputs,NumberOfTableDimensions)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    p_inputs = {};
    if strcmp(blk.UseOneInputPortForAllInputData, 'on')
        dimLen = numel(inputs{1})/NumberOfTableDimensions;
        for i=1:NumberOfTableDimensions
            p_inputs{i} = inputs{1}((i-1)*dimLen+1:i*dimLen);
        end
        inputs = p_inputs;
    end

end

