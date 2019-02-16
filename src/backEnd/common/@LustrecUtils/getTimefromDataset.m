%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

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
