function new_obj = changeArrowExp(obj, cond)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.BinaryExpr
    import nasa_toLustre.lustreAst.IteExpr
    if isequal(obj.op, BinaryExpr.ARROW)
        new_obj = IteExpr(cond, ...
            obj.left.changeArrowExp(cond),...
            obj.right.changeArrowExp(cond), ...
            true);
    else
        new_obj = BinaryExpr(obj.op,...
            obj.left.changeArrowExp(cond),...
            obj.right.changeArrowExp(cond), ...
            obj.withPar, obj.addEpsilon, obj.epsilon);
    end
end
