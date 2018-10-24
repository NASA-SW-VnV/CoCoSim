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
            obj.expr = expr;
        end
        function expr = getExp(obj)
            expr = obj.expr;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.expr)
                new_expr = cellfun(@(x) x.deepCopy(), obj.expr, 'UniformOutput', 0);
            else
                new_expr = obj.expr.deepCopy();
            end
            new_obj = ParenthesesExpr(new_expr);
        end
         
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            if iscell(obj.expr)
                [new_expr, varIds] = obj.expr{1}.changePre2Var();
            else
                [new_expr, varIds] = obj.expr.changePre2Var();
            end
            new_obj = ParenthesesExpr(new_expr);
        end
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.expr)
                new_expr = cellfun(@(x) x.changeArrowExp(cond), obj.expr, 'UniformOutput', 0);
            else
                new_expr = obj.expr.changeArrowExp(cond);
            end
            new_obj = ParenthesesExpr(new_expr);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            if iscell(obj.expr)
                varIds = obj.expr{1}.GetVarIds();
            else
                varIds = obj.expr.GetVarIds();
            end
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                if iscell(objects)
                    for i=1:numel(objects)
                        nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                    end
                else
                    nodesCalled = [nodesCalled, objects.getNodesCalled()];
                end
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

