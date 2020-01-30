classdef AssertExpr < nasa_toLustre.lustreAst.PropertyExpr
    %AssertExpr

    properties
    end
    
    methods
        function obj = AssertExpr(exp)
            obj = obj@nasa_toLustre.lustreAst.PropertyExpr('', exp);
        end
        new_obj = deepCopy(obj)
        code = print(obj, backend)
        code = print_lustrec(obj, backend)
        code = print_kind2(obj, backend)
        code = print_zustre(obj, backend)
        code = print_jkind(obj, backend)
        code = print_prelude(obj)
    end
    
end

