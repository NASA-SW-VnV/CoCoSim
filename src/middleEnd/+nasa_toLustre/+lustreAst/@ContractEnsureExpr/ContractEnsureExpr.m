classdef ContractEnsureExpr < nasa_toLustre.lustreAst.PropertyExpr
    %ContractEnsureExpr

    properties
    end
    
    methods
        function obj = ContractEnsureExpr(id, exp)
            obj = obj@nasa_toLustre.lustreAst.PropertyExpr(id, exp);
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

