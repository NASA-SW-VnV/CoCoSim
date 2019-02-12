
function data_map = createDataMap(inputs, inputs_dt)
    data_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for i=1:numel(inputs)
        for j=1:numel(inputs{i})
            data_map(inputs{i}{j}.getId()) = inputs_dt{i}{j};
        end
    end
end

