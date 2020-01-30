function obj = substituteVars(obj, oldVar, newVar)

    
    obj.left = obj.left.substituteVars( oldVar, newVar);
    obj.right = obj.right.substituteVars( oldVar, newVar);
end
