function new_obj = deepCopy(obj)

    new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.TupleExpr(new_args);
end
