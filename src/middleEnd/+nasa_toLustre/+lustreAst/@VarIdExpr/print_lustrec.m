function code = print_lustrec(obj, backend)

    
    id = obj.id;
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(id, '_')
        id = sprintf('x%s', id);
    end
    code = '';
    if ischar(id)
        code = id;
    end
end
