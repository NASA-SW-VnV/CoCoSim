function code = print(obj, backend)

    %TODO: check if LUSTREC syntax is OK for the other backends.
    
    if (LusBackendType.isKIND2(backend) || LusBackendType.isPRELUDE(backend))...
            && strcmp(obj.type, 'bool clock')
        dt = 'bool';
    else
        dt = obj.type;
    end
    id = obj.id;
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(id, '_')
        id = sprintf('x%s', id);
    end
    if LusBackendType.isPRELUDE(backend) ...
            && ~isempty(obj.rate)
        code = sprintf('%s : %s %s;', id, dt, obj.rate);
    elseif ~(LusBackendType.isKIND2(backend) || LusBackendType.isJKIND(backend)) ...
            && ~isempty(obj.clock)
        code = sprintf('%s : %s when %s;', id, dt, obj.clock);
    else
        code = sprintf('%s : %s;', id, dt);
    end
end
