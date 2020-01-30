function code = print_lustrec(obj, backend)

    exprs_cell = cellfun(@(x) sprintf('%s', x.print(backend)),...
        obj.exprs, 'UniformOutput', 0);
    exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
    
    code = sprintf('(merge %s\n\t\t %s)', obj.clock.print(backend), exprs_str);
end
