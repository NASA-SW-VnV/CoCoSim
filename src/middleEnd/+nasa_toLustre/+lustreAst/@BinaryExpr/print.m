function code = print(obj, backend)
    %% This function is used by KIND2 LustreProgram.print()

    code = obj.print_lustrec(backend);
end
