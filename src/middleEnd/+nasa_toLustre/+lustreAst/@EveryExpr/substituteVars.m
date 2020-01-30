function obj = substituteVars(obj, oldVar, newVar)

    obj.nodeArgs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.nodeArgs, 'UniformOutput', 0);
    obj.cond = obj.cond.substituteVars(oldVar, newVar);
end
