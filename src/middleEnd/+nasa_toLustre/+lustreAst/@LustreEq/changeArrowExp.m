function new_obj = changeArrowExp(obj, cond)

    new_rhs = obj.rhs.changeArrowExp(cond);
    new_obj = nasa_toLustre.lustreAst.LustreEq(obj.lhs, new_rhs);
end
