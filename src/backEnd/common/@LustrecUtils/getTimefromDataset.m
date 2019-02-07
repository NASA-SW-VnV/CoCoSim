
%% run comparaison
function time = getTimefromDataset(ds)
    time = [];
    if isa(ds, 'Simulink.SimulationData.Dataset')
        time = LustrecUtils.getTimefromDataset(ds{1}.Values);
    elseif isa(ds, 'timeseries')
        time = ds.Time;
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        if numel(fields) >= 1
            time = LustrecUtils.getTimefromDataset(ds.(fields{1}));
        end
    end
end
