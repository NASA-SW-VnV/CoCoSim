function new_obj = changeArrowExp(obj, cond)

    new_exprs = cellfun(@(x) x.changeArrowExp(cond), obj.exprs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
