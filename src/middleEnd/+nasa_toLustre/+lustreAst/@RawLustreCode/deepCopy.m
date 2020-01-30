function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.RawLustreCode(obj.code, obj.name);
end
