function r = ismemberVar(v, vars)

    
    
    if iscell(v)
        r = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(x, vars), v);
        return;
    end
    if isa(v, 'nasa_toLustre.lustreAst.VarIdExpr') || isa(v, 'nasa_toLustre.lustreAst.LustreVar')
        v = v.getId();
    end
    Ids = cellfun(@(x) x.getId(), ...
        vars, 'UniformOutput', false);
    r = ismember(v, Ids);
end
