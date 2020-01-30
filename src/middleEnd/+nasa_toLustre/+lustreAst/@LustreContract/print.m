function code = print(obj, backend, varargin)

    if LusBackendType.isKIND2(backend)
        code = obj.print_kind2(backend);
    else
        code = '';
    end
end
