function code = print(obj, backend)

    
    if LusBackendType.isPRELUDE(backend)
        code = obj.print_prelude();
    else
        if isempty(obj.id) || LusBackendType.isJKIND(backend)
            %Jkind does not support ID
            code = sprintf('--%%PROPERTY %s;', ...
                obj.exp.print(backend));
        else
            code = sprintf('--%%PROPERTY "%s" %s;', ...
                obj.id, ...
                obj.exp.print(backend));
        end
    end
end
