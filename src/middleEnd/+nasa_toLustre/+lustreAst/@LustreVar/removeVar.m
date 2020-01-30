function U = removeVar(vars, v)

    if isa(v, 'nasa_toLustre.lustreAst.VarIdExpr') || isa(v, 'nasa_toLustre.lustreAst.LustreVar')
        v = v.getId();
    end
    Ids = cellfun(@(x) x.getId(), ...
        vars, 'UniformOutput', false);
    U = vars(~strcmp(Ids, v));
end
