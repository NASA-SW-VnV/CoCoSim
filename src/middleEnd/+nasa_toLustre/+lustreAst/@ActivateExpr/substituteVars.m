function new_obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    % we do not substitute vars in conditions as limitation of lustrec bool
    % clock variables.
    new_args = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ActivateExpr(obj.nodeName, ...
        new_args, obj.activate_cond,...
        obj.has_restart, obj.restart_cond);
end
