
function width = getSignalWidth(ds)
    width = 0;
    if isa(ds, 'timeseries')
        width = prod(ds.getdatasamplesize);
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        for i=1:numel(fields)
            width = width + ...
                LustrecUtils.getSignalWidth(ds.(fields{i}));
        end
    end
end
