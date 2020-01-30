function new_obj = simplify(obj)

    new_args = cellfun(@(x) x.simplify(), obj.nodeArgs, 'UniformOutput', 0);
    if obj.has_restart
        restart_cond = obj.restart_cond.simplify();
    else
        restart_cond = obj.restart_cond;
    end
    new_obj = nasa_toLustre.lustreAst.ActivateExpr(obj.nodeName, ...
        new_args, obj.activate_cond.simplify(), obj.has_restart, restart_cond);
end
