
%% change events to data
function data = eventsToData(event_s)
    data = cell(numel(event_s), 1);
    for i=1:numel(event_s)
        data{i} = event_s{i};
        if isequal(data{i}.Scope, 'Input')
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
