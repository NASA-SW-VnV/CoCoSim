function new_obj = changeArrowExp(obj, cond)

    new_args = cellfun(@(x) x.changeArrowExp(cond), obj.nodeArgs, 'UniformOutput', 0);
    
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond.changeArrowExp(cond));
end
