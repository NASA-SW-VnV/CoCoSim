
function number_of_inputs = getNumberOfInputs(ds, nb_steps)
    number_of_inputs = 0;
    if isa(ds, 'Simulink.SimulationData.Dataset')
        for i=1:numel(ds.getElementNames)
            number_of_inputs = number_of_inputs + ...
                LustrecUtils.getNumberOfInputs(ds{i}.Values, nb_steps);
        end
    elseif isa(ds, 'timeseries')
        dim = ds.getdatasamplesize;
        number_of_inputs = nb_steps*(prod(dim));
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        for i=1:numel(fields)
            number_of_inputs = number_of_inputs + ...
                LustrecUtils.getNumberOfInputs(ds.(fields{i}), nb_steps);
        end
    end
end
