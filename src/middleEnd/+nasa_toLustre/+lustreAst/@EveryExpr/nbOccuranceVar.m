function nb_occ = nbOccuranceVar(obj, var)

    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.nodeArgs, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq) + obj.cond.nbOccuranceVar(var);
end
