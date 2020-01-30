function data = eventsToData(event_s)
    %% change events to data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    data = cell(numel(event_s), 1);
    for i=1:numel(event_s)
        data{i} = event_s{i};
        if strcmp(data{i}.Scope, 'Input')
            data{i}.Port = data{i}.Port - numel(event_s);%for ordering reasons
        end
        data{i}.LusDatatype = 'bool';
        data{i}.Datatype = 'Event';
        data{i}.CompiledType = 'boolean';
        data{i}.InitialValue = 'false';
        data{i}.ArraySize = '1';
        data{i}.CompiledSize = '1';
    end
end
