function obj = substituteVars(obj, var, newVar)

    obj.expr = obj.expr.substituteVars(var, newVar);
end
