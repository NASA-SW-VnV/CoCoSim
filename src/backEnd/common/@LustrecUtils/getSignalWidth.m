%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function width = getSignalWidth(ds)
    width = 0;
    if isa(ds, 'timeseries')
        width = prod(ds.getdatasamplesize);
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        for i=1:numel(ds)
            for j=1:numel(fields)
                width = width + ...
                    LustrecUtils.getSignalWidth(ds(i).(fields{j}));
            end
        end
    end
end
