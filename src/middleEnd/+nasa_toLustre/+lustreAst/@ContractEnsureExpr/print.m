function code = print(obj, backend)

    
    if LusBackendType.isPRELUDE(backend)
        code = obj.print_prelude();
    else
        if isempty(obj.id) 
            code = sprintf('\t\tensure %s;\n', ...
                obj.exp.print(backend));
        else
            code = sprintf('\t\tensure "%s" %s;', ...
                obj.id, ...
                obj.exp.print(backend));
        end
    end
end
