function [new_obj, varIds] = changePre2Var(obj)

    varIds = {};
    new_exprs = {};
    for i=1:numel(obj.nodeArgs)
        [new_exprs{i}, varIds_i] = obj.nodeArgs{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    [condE, varId] = obj.cond.changePre2Var();
    varIds = [varIds, varId];
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_exprs, condE);
end
