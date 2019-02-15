function new_obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_obj = nasa_toLustre.lustreAst.IteExpr(...
        obj.condition.substituteVars(oldVar, newVar),...
        obj.thenExpr.substituteVars(oldVar, newVar),...
        obj.ElseExpr.substituteVars(oldVar, newVar),...
        obj.OneLine);
end
