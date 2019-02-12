
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function in_matrix_dimension = getDimensionsFromBusObject(busName)
    in_matrix_dimension = {};
    bus = evalin('base', char(busName));
    try
        elems = bus.Elements;
    catch
        % Elements is not in bus.
        return;
    end
    for i=1:numel(elems)
        dt = elems(i).DataType;
        dt = strrep(dt, 'Bus: ', '');
        isBus = SLXUtils.isSimulinkBus(char(dt));

        if isBus
            dt = regexprep(dt, 'Bus:\s*', '');
            in_matrix_dimension = [in_matrix_dimension,...
                nasa_toLustre.utils.SLX2LusUtils.getDimensionsFromBusObject(dt)];
        else
            dimensions = elems(i).Dimensions;
            idx = numel(in_matrix_dimension) +1;
            in_matrix_dimension{idx}.dims = dimensions;
            in_matrix_dimension{idx}.width = prod(dimensions);
            in_matrix_dimension{idx}.numDs = numel(dimensions);
        end
    end
end
