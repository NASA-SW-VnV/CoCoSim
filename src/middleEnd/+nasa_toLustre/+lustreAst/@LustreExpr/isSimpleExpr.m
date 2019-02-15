function r = isSimpleExpr(expr)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    r = isa(expr, 'nasa_toLustre.lustreAst.VarIdExpr')...
        || isa(expr, 'nasa_toLustre.lustreAst.IntExpr')...
        || isa(expr, 'nasa_toLustre.lustreAst.RealExpr')...
        || isa(expr, 'nasa_toLustre.lustreAst.BooleanExpr')...
        || isa(expr, 'nasa_toLustre.lustreAst.EnumValueExpr');
end
