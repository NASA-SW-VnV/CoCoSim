function [new_obj, varIds] = changePre2Var(obj)

    varIds = {};
    new_exprs = {};
    for i=1:numel(obj.exprs)
        [new_exprs{i}, varIds_i] = obj.exprs{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
