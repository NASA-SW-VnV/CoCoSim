function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map),...
        obj.args, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
