function obj = substituteVars(obj, var, newVar)

    obj.args = cellfun(@(x) x.substituteVars(var, newVar), obj.args, 'UniformOutput', 0);
end
