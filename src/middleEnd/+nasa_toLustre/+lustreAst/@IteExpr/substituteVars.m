function obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    obj.condition = obj.condition.substituteVars(oldVar, newVar);
    obj.thenExpr = obj.thenExpr.substituteVars(oldVar, newVar);
    obj.ElseExpr = obj.ElseExpr.substituteVars(oldVar, newVar);
end
