function code = print(obj, backend)

    %TODO: check if LUSTREC syntax is OK for the other backends.
    code = obj.print_lustrec(backend);
end
