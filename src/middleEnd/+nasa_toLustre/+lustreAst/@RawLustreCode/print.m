function code = print(obj, varargin)

    %TODO: check if LUSTREC syntax is OK for the other backends.
    code = obj.print_lustrec();
end
