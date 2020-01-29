function new_obj = deepCopy(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
        obj.left.deepCopy(),...
        obj.right.deepCopy(), ...
        obj.withPar, obj.addEpsilon, obj.epsilon, obj.operandsDT);
end
