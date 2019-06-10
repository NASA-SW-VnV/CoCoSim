function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
        obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond);
end
