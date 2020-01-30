function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %UnaryExpr is always on the right of an Equation
    [new_expr, ~] = obj.expr.pseudoCode2Lustre(outputs_map, false, node, data_map);
    new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op,...
        new_expr,...
        obj.withPar);
end
