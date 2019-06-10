function U = removeVar(vars, v)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if isa(v, 'nasa_toLustre.lustreAst.VarIdExpr') || isa(v, 'nasa_toLustre.lustreAst.LustreVar')
        v = v.getId();
    end
    Ids = cellfun(@(x) x.getId(), ...
        vars, 'UniformOutput', false);
    U = vars(~strcmp(Ids, v));
end
