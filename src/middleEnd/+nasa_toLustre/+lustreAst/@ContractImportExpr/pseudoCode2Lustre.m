function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    new_outputs = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map), obj.outputs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractImportExpr(obj.name, ...
        obj.inputs, new_outputs);
end
