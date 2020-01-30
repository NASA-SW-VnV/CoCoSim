function code = print(obj, backend)

    
    if LusBackendType.isPRELUDE(backend)
        code = obj.print_prelude();
    else
        code = sprintf('\t\trequire %s;\n', ...
                obj.exp.print(backend));
    end
end
