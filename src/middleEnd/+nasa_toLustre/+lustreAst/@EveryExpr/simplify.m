function new_obj = simplify(obj)

    new_args = cellfun(@(x) x.simplify(), obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond.simplify());
end
