function [c2] = cellCartesianProduct(c1)
    indices = cell(1, numel(c1));   %output variable for ndgrid
    ndgridin = cellfun(@(c) 1:numel(c), c1, 'UniformOutput', false); %input arrays for ndgrid
    [indices{:}] = ndgrid(ndgridin{:}); %get ngrid result
    indices = cellfun(@(idx) reshape(idx, [], 1), indices, 'UniformOutput', false); %reshape ndgrid outputs into columns
    catfun = @(nset, subsets) [arrayfun(@(n, i) c1{n}{i}, nset, subsets, 'UniformOutput', false)];
    c2 = arrayfun(@(varargin) catfun(1:numel(c1), [varargin{:}]), indices{:}, 'UniformOutput', false);
    c2 = vertcat(c2{:});
end

