function [new_obj, varIds] = changePre2Var(obj)

    varIds = {};
    new_exprs = {};
    for i=1:numel(obj.nodeArgs)
        [new_exprs{i}, varIds_i] = obj.nodeArgs{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    [condA, varId] = obj.activate_cond.changePre2Var();
    varIds = [varIds, varId];
    if obj.has_restart
        [condR, varId] = obj.restart_cond.changePre2Var();
        varIds = [varIds, varId];
    else
        condR = obj.restart_cond;
    end
    new_obj = nasa_toLustre.lustreAst.ActivateExpr(obj.nodeName, ...
        new_exprs, condA, obj.has_restart, condR);
end
