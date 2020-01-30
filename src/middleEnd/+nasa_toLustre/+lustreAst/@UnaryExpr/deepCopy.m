function new_obj = deepCopy(obj)

    new_expr = obj.expr.deepCopy();
    new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
end
