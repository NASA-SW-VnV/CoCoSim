function nb_occ = nbOccuranceVar(obj, var)

    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.args, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq);
end
