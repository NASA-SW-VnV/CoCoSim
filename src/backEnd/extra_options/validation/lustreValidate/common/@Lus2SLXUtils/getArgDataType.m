function [dt, dim] = getArgDataType(arg)
    dt = '';
    dim = 1;
    if isfield(arg, 'type') && strcmp(arg.type, 'array access')
        [dt, dim] = Lus2SLXUtils.getArgDataType(arg.array);
    elseif isfield(arg, 'datatype')
        if isstruct(arg.datatype)
            if isfield(arg.datatype, 'kind') 
                if strcmp(arg.datatype.kind, 'array')
                    dt = Lus2SLXUtils.getArgDataType(arg.datatype);
                    dim = getArrayDim(arg.datatype);
                else
                    dt = arg.datatype.kind;
                end
            end
        else
            dt = arg.datatype;
        end
    elseif isfield(arg, 'base_type')
        if isfield(arg.base_type, 'kind') 
            if strcmp(arg.base_type.kind, 'array')
                dt = Lus2SLXUtils.getArgDataType(arg.base_type);
            else
                dt = arg.base_type.kind;
            end
        end
    end
end

function dim = getArrayDim(datatype)
    dim = [];
    base_type = datatype;
    while(isfield(base_type, 'base_type'))
        if isfield(base_type, 'dim')
            dim = [str2num(base_type.dim.value), dim];
        end
        base_type = base_type.base_type;
    end
    
end