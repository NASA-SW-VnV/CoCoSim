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

function values = get_random_bus_values(bus, time, min, max, dim)
    values = [];
    if prod(dim) > 1
        errordlg('Array Bus Signals are not supported for simulation. Work in progress!');
    end
    try
        elems = bus.getLeafBusElements;
    catch
        return;
    end
    for i=1:numel(elems)
        dt = elems(i).DataType;
        dim = elems(i).Dimensions;
        values.(elems(i).Name) = SLXUtils.get_random_values_InTimeSeries(time, min, max, dim, dt);
    end
end
