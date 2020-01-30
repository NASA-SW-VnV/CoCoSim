function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    new_exprs = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map),...
        obj.exprs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
