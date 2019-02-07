
function values = construct_random_bus_values(bus, time, nb_steps, min, max, dim)
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
        values.(elems(i).Name) = SLXUtils.get_random_values(time, nb_steps, min, max, dim, dt);
    end
end
