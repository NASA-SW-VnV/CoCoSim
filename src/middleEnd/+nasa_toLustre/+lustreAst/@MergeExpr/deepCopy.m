function new_obj = deepCopy(obj)

    new_exprs = cellfun(@(x) x.deepCopy(), obj.exprs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
