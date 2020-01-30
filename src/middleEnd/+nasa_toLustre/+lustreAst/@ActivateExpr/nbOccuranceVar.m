function nb_occ = nbOccuranceVar(obj, var)

    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.nodeArgs, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq) + obj.activate_cond.nbOccuranceVar(var);
    if obj.has_restart
        nb_occ = nb_occ + obj.has_restart.nbOccuranceVar(var);
    end
end
