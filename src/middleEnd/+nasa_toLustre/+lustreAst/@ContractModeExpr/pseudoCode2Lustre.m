function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    new_requires = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
        obj.requires, ...
        'UniformOutput', 0);
    new_ensures = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
        obj.ensures, ...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractModeExpr(obj.name, new_requires, new_ensures);
end
