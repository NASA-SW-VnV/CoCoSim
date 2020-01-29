
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% Bus signal Lustre dataType
function lustreTypes = getLustreTypesFromBusObject(busName)
    bus = evalin('base', char(busName));
    lustreTypes = {};
    try
        elems = bus.Elements;
    catch
        % Elements is not in bus.
        return;
    end
    for i=1:numel(elems)
        dt = elems(i).DataType;
        dimensions = elems(i).Dimensions;
        width = prod(dimensions);
        if strncmp(dt, 'Bus:', 4)
            dt = regexprep(dt, 'Bus:\s*', '');
        end
        lusDT = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( dt);
        for w=1:width
            if iscell(lusDT)
                lustreTypes = [lustreTypes, lusDT];
            else
                lustreTypes{end+1} = lusDT;
            end
        end
    end
end
