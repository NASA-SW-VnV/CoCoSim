function new_obj = simplify(obj)

    new_exprs = cellfun(@(x) x.simplify(), obj.exprs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
