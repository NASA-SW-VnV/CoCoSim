classdef UnaryExpr < LustreExpr
    %UnaryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        op;
        expr;
        withPar; %with parentheses
    end
    properties(Constant)
        NOT = 'not';
        PRE = 'pre';
        LAST = 'last';
        NEG = '-';
        REAL = 'real';
        INT = 'int';
        
    end
    methods
        function obj = UnaryExpr(op, expr, withPar)
            obj.op = op;
            obj.expr = expr;
            if exist('withPar', 'var')
                obj.withPar = withPar;
            else
                obj.withPar = true;
            end
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.expr)
                new_expr = cellfun(@(x) x.deepCopy(), obj.expr, 'UniformOutput', 0);
            else
                new_expr = obj.expr.deepCopy();
            end
            new_obj = UnaryExpr(obj.op, new_expr, obj.withPar);
        end
        
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            if obj.withPar
                code = sprintf('(%s %s)', ...
                    obj.op, ...
                    obj.expr.print(backend));
            else
                code = sprintf('%s %s', ...
                    obj.op, ...
                    obj.expr.print(backend));
            end
            
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end
    
end

