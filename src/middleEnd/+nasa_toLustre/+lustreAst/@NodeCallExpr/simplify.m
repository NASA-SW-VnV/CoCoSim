function new_obj = simplify(obj)

    new_args = cellfun(@(x) x.simplify(), obj.args, 'UniformOutput', 0);
    
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
