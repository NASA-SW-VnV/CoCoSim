%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function Values = get_random_values_InTimeSeries(time, min, max, dim, dt)
    [isBus, bus] = SLXUtils.isSimulinkBus(dt);
    nb_steps = length(time);
    if isBus
        % This function differs from the one inside get_random_values, it generate
        % timeseries and not vector of values.
        Values = get_random_bus_values(bus, time, min, max, dim);
    else
        Values = timeseries(...
            SLXUtils.get_random_values(nb_steps, min, max, dim, dt), ...
            time);
    end
end

function values = get_random_bus_values(bus, time, min, max, busDim)
    values = struct();
%     if prod(dim) > 1
%         errordlg('Array Bus Signals are not supported for simulation. Work in progress!');
%     end
    try
        elems = bus.getLeafBusElements;
    catch
        return;
    end
    width = prod(busDim);
    for i=1:width
        for j=1:numel(elems)
            dt = elems(j).DataType;
            dim = elems(j).Dimensions;
            values(i).(elems(j).Name) = SLXUtils.get_random_values_InTimeSeries(time, min, max, dim, dt);
        end
    end
    if width > 1 && length(busDim) > 1
        % go back to dimension
        values = reshape(values, busDim);
    end
end
