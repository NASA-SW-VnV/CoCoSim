function new_obj = changeArrowExp(obj, cond)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    
    if strcmp(obj.op, nasa_toLustre.lustreAst.BinaryExpr.ARROW)
        new_obj = nasa_toLustre.lustreAst.IteExpr(cond, ...
            obj.left.changeArrowExp(cond),...
            obj.right.changeArrowExp(cond), ...
            true);
    else
        new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
            obj.left.changeArrowExp(cond),...
            obj.right.changeArrowExp(cond), ...
            obj.withPar, obj.addEpsilon, obj.epsilon, obj.operandsDT);
    end
end
