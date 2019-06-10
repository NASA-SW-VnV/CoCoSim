classdef ParenthesesExpr < nasa_toLustre.lustreAst.LustreExpr
    %ParenthesesExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
        
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(obj, var)
        
        %% substituteVars
        new_obj = substituteVars(obj, var, newVar)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.expr}; obj.expr.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, cond)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.expr.GetVarIds();
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.expr);
        end
        
        %%
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

