function obj = substituteVars(obj, oldVar, newVar)

    obj.exprs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.exprs, 'UniformOutput', 0);
    if isa(obj, 'nasa_toLustre.lustreAst.MergeBoolExpr')
        obj.true_expr = obj.true_expr.substituteVars(oldVar, newVar);
        obj.false_expr = obj.false_expr.substituteVars(oldVar, newVar);
        obj.clock = obj.clock.substituteVars(oldVar, newVar);
    end
end
