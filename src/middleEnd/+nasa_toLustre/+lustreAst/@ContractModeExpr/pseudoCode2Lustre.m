function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    new_requires = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map),...
        obj.requires, ...
        'UniformOutput', 0);
    new_ensures = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map),...
        obj.ensures, ...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractModeExpr(obj.name, new_requires, new_ensures);
end
