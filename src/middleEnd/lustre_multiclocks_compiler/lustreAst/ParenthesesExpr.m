classdef ParenthesesExpr < LustreExpr
    %ParenthesesExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        expr;
    end
    
    methods
        function obj = ParenthesesExpr(expr)
            if iscell(expr) && numel(expr) == 1
                obj.expr = expr{1};
            else
                obj.expr = expr;
            end
        end
        function expr = getExp(obj)
            expr = obj.expr;
        end
        
        function new_obj = deepCopy(obj)
            new_expr = obj.expr.deepCopy();
            new_obj = ParenthesesExpr(new_expr);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_expr = obj.expr.simplify();
            new_obj = ParenthesesExpr(new_expr);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            [new_expr, varIds] = obj.expr.changePre2Var();
            new_obj = ParenthesesExpr(new_expr);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_expr = obj.expr.changeArrowExp(cond);
            new_obj = ParenthesesExpr(new_expr);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.expr.GetVarIds();
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            [new_exp, outputs_map] = obj.expr.pseudoCode2Lustre(outputs_map, isLeft);
            new_obj = ParenthesesExpr(new_exp);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.expr);
        end
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            code = sprintf('( %s )', obj.expr.print(backend));
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

