function new_obj = simplify(obj)

    new_obj = obj.substituteVars();
    new_localEqs = cellfun(@(x) x.simplify(), new_obj.bodyEqs, ...
        'UniformOutput', 0);
    new_obj.setBodyEqs(new_localEqs);
end
