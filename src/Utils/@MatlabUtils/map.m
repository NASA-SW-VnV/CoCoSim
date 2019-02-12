function f = map()
    f = @(val, fcns) cellfun(@(f) f(val{:}), fcns);
end

