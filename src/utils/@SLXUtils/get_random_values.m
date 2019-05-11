%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function Values = get_random_values(nb_steps, min, max, dim, dt)
    [isBus, bus] = SLXUtils.isSimulinkBus(dt);
    lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(dt);
    if isBus
        Values = get_random_bus_values(bus, nb_steps, min, max, dim);
    elseif strcmp(lus_dt,'bool')
        Values = ...
            MatlabUtils.construct_random_booleans(nb_steps, min, max, dim);
    elseif strcmp(dt,'int')
        Values = ...
            MatlabUtils.construct_random_integers(nb_steps, min, max, 'int32', dim);

    elseif MatlabUtils.contains(dt,'int')
        Values = ...
            MatlabUtils.construct_random_integers(nb_steps, min, max, dt, dim);
    elseif strcmp(dt,'single')
        Values = ...
            single(MatlabUtils.construct_random_doubles(nb_steps, min, max, dim));
    else
        Values = ...
            MatlabUtils.construct_random_doubles(nb_steps, min, max, dim);
    end
end


function values = get_random_bus_values(bus, nb_steps, min, max, dim)
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
        values.(elems(i).Name) = SLXUtils.get_random_values( nb_steps, min, max, dim, dt);
    end
end
