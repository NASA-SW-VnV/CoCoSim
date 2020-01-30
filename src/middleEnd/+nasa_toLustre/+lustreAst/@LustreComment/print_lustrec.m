function code = print_lustrec(obj, backend)

    
    if isempty(obj.text)
        return;
    end
    if LusBackendType.isPRELUDE(backend)
        code = sprintf('--%s\n',...
            strrep(obj.text, newline, '--'));
    else
        if obj.isMultiLine
            code = sprintf('(*\n%s\n*)\n', ...
                obj.text);
        else
            code = sprintf('--%s', ...
                obj.text);
        end
    end
end
