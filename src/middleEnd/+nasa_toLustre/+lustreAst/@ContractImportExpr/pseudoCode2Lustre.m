function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    new_outputs = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false, node, data_map), obj.outputs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractImportExpr(obj.name, ...
        obj.inputs, new_outputs);
end
