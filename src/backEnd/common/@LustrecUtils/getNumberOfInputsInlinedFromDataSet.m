%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function number_of_inputs = getNumberOfInputsInlinedFromDataSet(ds, nb_steps)
    number_of_inputs = 0;
    if isa(ds, 'Simulink.SimulationData.Dataset')
        for i=1:numel(ds.getElementNames)
            number_of_inputs = number_of_inputs + ...
                LustrecUtils.getNumberOfInputsInlinedFromDataSet(ds{i}.Values, nb_steps);
        end
    elseif isa(ds, 'timeseries')
        dim = ds.getdatasamplesize;
        number_of_inputs = nb_steps*(prod(dim));
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        for i=1:numel(ds)
            for j=1:numel(fields)
                number_of_inputs = number_of_inputs + ...
                    LustrecUtils.getNumberOfInputsInlinedFromDataSet(ds(i).(fields{j}), nb_steps);
            end
        end
    end
end
