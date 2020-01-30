function new_obj = deepCopy(obj)

    new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
