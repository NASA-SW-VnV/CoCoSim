function [new_obj, varIds] = changePre2Var(obj)

    v = obj.expr;
    if strcmp(obj.op, nasa_toLustre.lustreAst.UnaryExpr.PRE) && isa(v, 'nasa_toLustre.lustreAst.VarIdExpr')
        varIds{1} = v;
        new_obj = nasa_toLustre.lustreAst.VarIdExpr(strcat('_pre_', v.getId()));
    else
        [new_expr, varIds] = v.changePre2Var();
        new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
    end
end
