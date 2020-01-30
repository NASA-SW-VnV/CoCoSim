function new_obj = simplify(obj)

    new_lhs = obj.lhs.simplify();
    new_rhs = obj.rhs.simplify();
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
