function [conds, thens] = getCondsThens(exp)

        conds = {};
    thens = {};
    
    if ~isa(exp, 'nasa_toLustre.lustreAst.IteExpr')
        thens{1} = exp;
        return;
    end
    
    conds{1} = exp.getCondition();
    thens{1} = exp.getThenExpr();
    elseExp = exp.getElseExpr();
    [conds_i, thens_i] = nasa_toLustre.lustreAst.IteExpr.getCondsThens(elseExp);
    conds = MatlabUtils.concat(conds, conds_i);
    thens = MatlabUtils.concat(thens, thens_i);
end
