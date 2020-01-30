function new_obj = deepCopy(obj)

    new_lhs = obj.lhs.deepCopy();
    new_rhs = obj.rhs.deepCopy();
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
