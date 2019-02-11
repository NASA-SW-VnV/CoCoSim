
%% change events to data
function data = eventsToData(events)
    data = cell(numel(events), 1);
    for i=1:numel(events)
        data{i} = events{i};
        if isequal(data{i}.Scope, 'Input')
            data{i}.Port = data{i}.Port - numel(events);%for ordering reasons
        end
        data{i}.LusDatatype = 'bool';
        data{i}.Datatype = 'Event';
        data{i}.CompiledType = 'boolean';
        data{i}.InitialValue = 'false';
        data{i}.ArraySize = '1';
        data{i}.CompiledSize = '1';
    end
end
