function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    
    %BinaryExpr is always on the right of an Equation
    [leftExp, ~] = obj.left.pseudoCode2Lustre(outputs_map, false, node, data_map);
    [rightExp, ~] = obj.right.pseudoCode2Lustre(outputs_map, false, node, data_map);
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
        leftExp,...
        rightExp, ...
        obj.withPar, obj.addEpsilon, obj.epsilon, obj.operandsDT);
end
