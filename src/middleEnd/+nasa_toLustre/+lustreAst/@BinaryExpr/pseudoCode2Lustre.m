function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, ~)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    %BinaryExpr is always on the right of an Equation
    [leftExp, ~] = obj.left.pseudoCode2Lustre(outputs_map, false);
    [rightExp, ~] = obj.right.pseudoCode2Lustre(outputs_map, false);
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
        leftExp,...
        rightExp, ...
        obj.withPar, obj.addEpsilon, obj.epsilon);
end
