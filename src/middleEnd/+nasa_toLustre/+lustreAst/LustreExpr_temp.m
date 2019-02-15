classdef LustreExpr < nasa_toLustre.lustreAst.LustreAst
    %LustreExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods (Abstract)
        deepCopy(obj)
        changePre2Var(obj)
        simplify(obj)
        nbOccuranceVar(obj)
        getAllLustreExpr(obj)
        print(obj, backend)
        print_lustrec(obj)
        print_kind2(obj)
        print_zustre(obj)
        print_jkind(obj)
        print_prelude(obj)
    end
    methods(Static)
        function r = isSimpleExpr(expr)
            r = isa(expr, 'nasa_toLustre.lustreAst.VarIdExpr')...
                || isa(expr, 'nasa_toLustre.lustreAst.IntExpr')...
                || isa(expr, 'nasa_toLustre.lustreAst.RealExpr')...
                || isa(expr, 'nasa_toLustre.lustreAst.BooleanExpr')...
                || isa(expr, 'nasa_toLustre.lustreAst.EnumValueExpr');
        end
    end
end

