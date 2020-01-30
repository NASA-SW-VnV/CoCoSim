function U = uniqueVars(vars)

    Ids = cellfun(@(x) x.getId(), ...
        vars, 'UniformOutput', false);
    [~, I] = unique(Ids);
    U = vars(I);
end
