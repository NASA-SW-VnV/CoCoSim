%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% create random vector test
function [ds, ...
    simulation_step, ...
    stop_time] = get_random_test(slx_file_name, inports, nb_steps,IMAX, IMIN)

    if nargin < 3
        nb_steps = 100;
    end
    if nargin < 4
        IMAX = 500;
    end
    if nargin < 5
        IMIN = -500;
    end
    numberOfInports = numel(inports);
    try
        min = SLXUtils.getModelCompiledSampleTime(slx_file_name);
        if  min==0 || isnan(min) || min==Inf
            simulation_step = 1;
        else
            simulation_step = min;
        end

    catch
        simulation_step = 1;
    end
    stop_time = (nb_steps - 1)*simulation_step;
    time = (0:simulation_step:stop_time)';
    ds = Simulink.SimulationData.Dataset;
    for i=1:numberOfInports
        element = Simulink.SimulationData.Signal;
        element.Name = inports(i).name;
        if isfield(inports(i), 'dimension')
            dim = inports(i).dimension;
        else
            dim = 1;
        end
        if numel(IMIN) >= i && numel(IMAX) >= i
            min = IMIN(i);
            max = IMAX(i);
        else
            min = IMIN(1);
            max = IMAX(1);
        end
        element.Values = SLXUtils.get_random_values_InTimeSeries(time, min, max, dim, inports(i).datatype);
        ds{i} = element;
    end

end
