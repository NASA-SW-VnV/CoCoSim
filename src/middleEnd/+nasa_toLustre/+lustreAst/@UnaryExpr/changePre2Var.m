function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    import nasa_toLustre.lustreAst.*
    v = obj.expr;
    if isequal(obj.op, nasa_toLustre.lustreAst.UnaryExpr.PRE) && isa(v, 'VarIdExpr')
        varIds{1} = v;
        new_obj = nasa_toLustre.lustreAst.VarIdExpr(strcat('_pre_', v.getId()));
    else
        [new_expr, varIds] = v.changePre2Var();
        new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
    end
end
