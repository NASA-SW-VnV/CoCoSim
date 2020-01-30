function [new_obj, varIds] = changePre2Var(obj)

    [cond, vcondId] = obj.condition.changePre2Var();
    [then, thenCondId] = obj.thenExpr.changePre2Var();
    [elseE, elseCondId] = obj.ElseExpr.changePre2Var();
    varIds = [vcondId, thenCondId, elseCondId];
    new_obj = nasa_toLustre.lustreAst.IteExpr(cond, then, elseE, obj.OneLine);
end
