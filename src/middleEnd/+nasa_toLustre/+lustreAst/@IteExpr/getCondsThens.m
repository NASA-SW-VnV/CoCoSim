function [conds, thens] = getCondsThens(exp)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
        conds = {};
    thens = {};
    if isa(exp, 'nasa_toLustre.lustreAst.ParenthesesExpr')
        exp = exp.getExp();
    end
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
