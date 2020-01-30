function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    %UnaryExpr is always on the right of an Equation
    [new_expr, ~] = obj.expr.pseudoCode2Lustre(outputs_map, false, node, data_map);
    new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op,...
        new_expr,...
        obj.withPar);
end
