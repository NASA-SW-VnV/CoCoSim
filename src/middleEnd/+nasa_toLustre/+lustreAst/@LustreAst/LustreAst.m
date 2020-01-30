classdef LustreAst < handle
    %LustreAst

    properties
    end
    
    methods (Abstract)
        deepCopy(obj)
        changeArrowExp(obj, cond)
        changePre2Var(obj)
        print(obj, backend)
        print_lustrec(obj)
        print_kind2(obj)
        print_zustre(obj)
        print_jkind(obj)
        print_prelude(obj)
    end
    methods(Static)
        code = listVarsWithDT(vars, backend, forNodeHeader)
        
    end
end

