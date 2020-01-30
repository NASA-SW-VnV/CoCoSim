function new_obj = simplify(obj)

    new_expr = obj.expr.simplify();
    if isa(new_expr, 'nasa_toLustre.lustreAst.UnaryExpr') ...
            && strcmp(new_expr.op, obj.op) ...
            && (strcmp(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NOT) || strcmp(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NEG))
        % - - x => x, not not b => b
        new_obj = new_expr.expr;
    else
        new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
    end
end
