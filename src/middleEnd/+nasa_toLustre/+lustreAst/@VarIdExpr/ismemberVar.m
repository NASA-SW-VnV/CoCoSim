function r = ismemberVar(v, vars)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    import nasa_toLustre.lustreAst.VarIdExpr
    import nasa_toLustre.lustreAst.LustreVar
    if iscell(v)
        r = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(x, vars), v);
        return;
    end
    if isa(v, 'VarIdExpr') || isa(v, 'LustreVar')
        v = v.getId();
    end
    Ids = cellfun(@(x) x.getId(), ...
        vars, 'UniformOutput', false);
    r = ismember(v, Ids);
end
