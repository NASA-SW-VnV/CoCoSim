%% removeEmpty
function l = removeEmpty(l)
    l = l(cellfun(@(x) ~isempty(x), l));
end
