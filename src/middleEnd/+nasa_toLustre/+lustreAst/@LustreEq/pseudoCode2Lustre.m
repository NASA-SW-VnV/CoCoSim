function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    new_rhs = obj.rhs.pseudoCode2Lustre(outputs_map, false, node, data_map);
    [new_lhs, outputs_map] = obj.lhs.pseudoCode2Lustre(outputs_map, true, node, data_map);
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
