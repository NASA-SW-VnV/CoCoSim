function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
        new_expr = obj.expr.simplify();
    if isa(new_expr, 'nasa_toLustre.lustreAst.UnaryExpr') ...
            && strcmp(new_expr.op, obj.op) ...
            && (strcmp(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NOT) || strcmp(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NEG))
        % - - x => x, not not b => b
        new_obj = new_expr.expr;
    else
        new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
    end
end
