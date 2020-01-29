function [new_obj, varIds] = changePre2Var(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    
    varIds = {};
    [leftExp, varIdLeft] = obj.left.changePre2Var();
    varIds = [varIds, varIdLeft];
    [rightExp, varIdright] = obj.right.changePre2Var();
    varIds = [varIds, varIdright];
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
        leftExp,...
        rightExp, ...
        obj.withPar, obj.addEpsilon, obj.epsilon, obj.operandsDT);
end
