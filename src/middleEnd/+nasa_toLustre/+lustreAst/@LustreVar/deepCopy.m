function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.LustreVar(obj.id, obj.type, obj.rate, obj.clock);
end
