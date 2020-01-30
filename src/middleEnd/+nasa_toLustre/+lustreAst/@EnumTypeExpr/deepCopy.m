function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.EnumTypeExpr(obj.enum_name, obj.enum_args);
end
