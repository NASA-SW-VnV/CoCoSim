function code = print(obj, backend)

    
    if LusBackendType.isKIND2(backend)
        code = obj.print_kind2(backend);
    else
        %TODO: check if LUSTREC syntax is OK for the other backends.
        code = obj.print_lustrec(backend);
    end
end
