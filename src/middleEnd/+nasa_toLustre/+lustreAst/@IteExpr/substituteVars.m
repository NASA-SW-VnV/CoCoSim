function obj = substituteVars(obj, oldVar, newVar)

    
    obj.condition = obj.condition.substituteVars(oldVar, newVar);
    obj.thenExpr = obj.thenExpr.substituteVars(oldVar, newVar);
    obj.ElseExpr = obj.ElseExpr.substituteVars(oldVar, newVar);
end
