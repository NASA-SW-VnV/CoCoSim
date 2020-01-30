function obj = substituteVars(obj, oldVar, newVar)

    obj.lhs = obj.lhs;
    obj.rhs = obj.rhs.substituteVars(oldVar, newVar);
end
