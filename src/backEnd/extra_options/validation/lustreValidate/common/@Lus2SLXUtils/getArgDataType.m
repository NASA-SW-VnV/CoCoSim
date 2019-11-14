function dt = getArgDataType(arg)
    dt = '';
    if isfield(arg, 'type') && strcmp(arg.type, 'array access')
        dt = Lus2SLXUtils.getArgDataType(arg.array);
    elseif isfield(arg, 'datatype')
        if isstruct(arg.datatype)
            if isfield(arg.datatype, 'kind') 
                if strcmp(arg.datatype.kind, 'array')
                    dt = arg.datatype.base_type.kind;
                else
                    dt = arg.datatype.kind;
                end
            end
        else
            dt = arg.datatype;
        end
    end
end

