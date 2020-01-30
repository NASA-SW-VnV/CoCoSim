function data_map = createDataMap(inputs, inputs_dt)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    data_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for i=1:numel(inputs)
        for j=1:numel(inputs{i})
            data_map(inputs{i}{j}.getId()) = inputs_dt{i}{j};
        end
    end
end

