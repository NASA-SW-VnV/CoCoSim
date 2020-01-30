function new_obj = changeArrowExp(obj, cond)

    new_expr = obj.expr.changeArrowExp(cond);
    new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
end
