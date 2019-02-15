function new_obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_lhs = obj.lhs.substituteVars(oldVar, newVar);
    new_rhs = obj.rhs.substituteVars(oldVar, newVar);
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
