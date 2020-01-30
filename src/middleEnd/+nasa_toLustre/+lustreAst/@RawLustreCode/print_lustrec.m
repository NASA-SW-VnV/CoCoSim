function code = print_lustrec(obj)

    if ischar(obj.code)
        code = obj.code;
    elseif isempty(obj.code)
        code = '';
    end
end
