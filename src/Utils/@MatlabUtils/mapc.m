function f = mapc()
    f = @(val, fcns) cellfun(@(f) f(val{:}), fcns, 'UniformOutput', 0);
end

