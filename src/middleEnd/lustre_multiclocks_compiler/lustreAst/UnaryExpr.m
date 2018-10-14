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
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            if iscell(obj.expr)
                v = obj.expr{1};
            else
                v = obj.expr;
            end
            if isequal(obj.op, UnaryExpr.PRE) && isa(v, 'VarIdExpr')
                varIds{1} = v;
                new_obj = VarIdExpr(strcat('_pre_', v.getId()));
            else
                [new_expr, varIds] = v.changePre2Var();
                new_obj = UnaryExpr(obj.op, new_expr, obj.withPar);
            end
        end
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.expr)
                new_expr = cellfun(@(x) x.changeArrowExp(cond), obj.expr, 'UniformOutput', 0);
            else
                new_expr = obj.expr.changeArrowExp(cond);
            end
            new_obj = UnaryExpr(obj.op, new_expr, obj.withPar);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            if iscell(obj.expr)
                varIds = obj.expr{1}.GetVarIds();
            else
                varIds = obj.expr.GetVarIds();
            end
        end
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            if iscell(obj.expr) && numel(obj.expr) == 1
                obj.expr = obj.expr{1};
            end
            
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

