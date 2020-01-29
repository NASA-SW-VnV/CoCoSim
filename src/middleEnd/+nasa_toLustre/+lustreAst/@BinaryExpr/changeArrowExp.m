function new_obj = changeArrowExp(obj, cond)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    
    
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
