
function vars = getDataVars(d_list)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    vars = {};
    for i=1:numel(d_list)
        names = SF_To_LustreNode.getDataName(d_list{i});
        lusDt = d_list{i}.LusDatatype;
        vars = MatlabUtils.concat(vars, ...
            cellfun(@(x) LustreVar(x, lusDt), ...
            names, 'UniformOutput', false));
    end
end
