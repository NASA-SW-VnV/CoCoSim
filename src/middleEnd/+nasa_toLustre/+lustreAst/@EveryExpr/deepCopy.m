function new_obj = deepCopy(obj)

    new_args = cellfun(@(x) x.deepCopy(), obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond.deepCopy());
end
