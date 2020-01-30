function [lus_code, plu_code, ext_lib] = print(obj, backend)

    %TODO: check if LUSTREC syntax is OK for the other backends.
    [lus_code, plu_code, ext_lib] = obj.print_lustrec(backend);
end
