function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map),...
        obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond);
end
