function code = print(obj, ~)

    %TODO: check if LUSTREC syntax is OK for the other backends.
    code = obj.print_lustrec();
end
