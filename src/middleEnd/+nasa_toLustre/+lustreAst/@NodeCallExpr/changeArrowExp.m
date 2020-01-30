function new_obj = changeArrowExp(obj, cond)

    new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
    
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
