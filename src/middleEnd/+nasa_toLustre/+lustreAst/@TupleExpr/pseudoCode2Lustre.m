function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

    new_args = cell(numel(obj.args), 1);
    for i=1:numel(obj.args)
        [new_args{i}, outputs_map] = ...
            obj.args{i}.pseudoCode2Lustre(outputs_map, isLeft, node, data_map);
    end
    new_obj = nasa_toLustre.lustreAst.TupleExpr(new_args);
end
