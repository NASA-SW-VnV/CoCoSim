function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    new_op = obj.op;
    left_exp = obj.left.simplify();
    right_exp = obj.right.simplify();
    % x + (-y) => x - y, x - (-y) => x+y
    if isa(right_exp, 'UnaryExpr') ...
            && isequal(right_exp.op, nasa_toLustre.lustreAst.UnaryExpr.NEG) 
        if isequal(new_op, nasa_toLustre.lustreAst.BinaryExpr.PLUS)
            right_exp = right_exp.expr;
            new_op = nasa_toLustre.lustreAst.BinaryExpr.MINUS;
        elseif isequal(new_op, nasa_toLustre.lustreAst.BinaryExpr.MINUS)
            right_exp = right_exp.expr;
            new_op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
        end
    end
    % x+0 => x, x -0 => x
    if (isequal(new_op, nasa_toLustre.lustreAst.BinaryExpr.MINUS) ...
            || isequal(new_op, nasa_toLustre.lustreAst.BinaryExpr.PLUS) )
        if isequal(new_op, nasa_toLustre.lustreAst.BinaryExpr.PLUS) ...
                && (isa(left_exp, 'IntExpr') || isa(left_exp, 'RealExpr'))...
                && left_exp.getValue() == 0
            new_obj = right_exp;
            return;
        end
        if (isa(right_exp, 'IntExpr') || isa(right_exp, 'RealExpr'))...
                && right_exp.getValue() == 0
            new_obj = left_exp;
            return;
        end
    end
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(new_op,...
        left_exp,...
        right_exp, ...
        obj.withPar, obj.addEpsilon, obj.epsilon);
end
