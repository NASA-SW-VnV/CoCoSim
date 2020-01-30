function obj = substituteVars(obj, oldVar, newVar)

    % we do not substitute vars in conditions as limitation of lustrec bool
    % clock variables.
    obj.nodeArgs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.nodeArgs, 'UniformOutput', 0);
end
