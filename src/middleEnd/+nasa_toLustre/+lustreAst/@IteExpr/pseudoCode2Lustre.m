function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.pseudoCode2Lustre(outputs_map, false),...
        obj.thenExpr.pseudoCode2Lustre(outputs_map, false),...
        obj.ElseExpr.pseudoCode2Lustre(outputs_map, false),...
        obj.OneLine);
end
