classdef LustreExpr < nasa_toLustre.lustreAst.LustreAst
    %LustreExpr

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
        r = isSimpleExpr(expr)
    end
end

