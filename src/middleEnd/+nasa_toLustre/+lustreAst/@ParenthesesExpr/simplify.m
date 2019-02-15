function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    
    if isa(obj.expr, 'nasa_toLustre.lustreAst.ParenthesesExpr')
        new_obj = obj.expr.simplify();
    else
        new_expr = obj.expr.simplify();
        if nasa_toLustre.lustreAst.LustreExpr.isSimpleExpr(new_expr)
            new_obj = new_expr;
        else
            new_obj = nasa_toLustre.lustreAst.ParenthesesExpr(new_expr);
        end
    end
end
