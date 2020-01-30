function new_obj = deepCopy(obj)

    new_args = cellfun(@(x) x.deepCopy(), obj.nodeArgs, 'UniformOutput', 0);
    if obj.has_restart
        restart_cond = obj.restart_cond.deepCopy();
    else
        restart_cond = obj.restart_cond;
    end
    new_obj = nasa_toLustre.lustreAst.ActivateExpr(obj.nodeName, ...
        new_args, obj.activate_cond.deepCopy(), obj.has_restart, restart_cond);
end
