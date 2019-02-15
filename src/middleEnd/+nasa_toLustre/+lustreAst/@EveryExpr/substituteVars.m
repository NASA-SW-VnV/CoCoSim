function new_obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_args = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.nodeArgs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_args, obj.cond);
end
