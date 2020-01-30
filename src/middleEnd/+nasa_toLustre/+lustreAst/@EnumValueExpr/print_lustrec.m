function code = print_lustrec(obj, ~)

    % it should start with upper case
    if numel(obj.enum_name) > 1
        code = sprintf('%s%s', upper(obj.enum_name(1)), obj.enum_name(2:end));
    else
        code = upper(obj.enum_name);
    end
end
