function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    vId = nasa_toLustre.lustreAst.VarIdExpr(obj.id);
    [new_vId, outputs_map] = vId.pseudoCode2Lustre(outputs_map, isLeft, node, data_map);
    new_obj = nasa_toLustre.lustreAst.LustreVar(new_vId, obj.type);
end
