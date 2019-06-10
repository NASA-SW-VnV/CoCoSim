function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
        obj.nodeArgs, 'UniformOutput', 0);
    activate_cond = obj.activate_cond.pseudoCode2Lustre(outputs_map, false);
    if obj.has_restart
        restart_cond = obj.restart_cond.pseudoCode2Lustre(outputs_map, false);
    end
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, activate_cond, obj.has_restart, restart_cond);
end
