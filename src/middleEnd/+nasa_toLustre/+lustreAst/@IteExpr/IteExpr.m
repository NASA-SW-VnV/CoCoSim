classdef IteExpr < nasa_toLustre.lustreAst.LustreExpr
    %IteExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        condition;
        thenExpr;
        ElseExpr;
        OneLine;% to print it in one line
    end
    
    methods
        function obj = IteExpr(condition, thenExpr, ElseExpr, OneLine)
            if iscell(condition)
                obj.condition = condition{1};
            else
                obj.condition = condition;
            end
            if iscell(thenExpr)
                obj.thenExpr = thenExpr{1};
            else
                obj.thenExpr = thenExpr;
            end
            if iscell(ElseExpr)
                obj.ElseExpr = ElseExpr{1};
            else
                obj.ElseExpr = ElseExpr;
            end
            if nargin < 4
                obj.OneLine = false;
            else
                obj.OneLine = OneLine;
            end
        end
        %% getters
        function c = getCondition(obj)
            c = obj.condition;
        end
        function c = getThenExpr(obj)
            c = obj.thenExpr;
        end
        function c = getElseExpr(obj)
            c = obj.ElseExpr;
        end
        
        %%
        new_obj = deepCopy(obj)
            
        
        %% simplify expression
        new_obj = simplify(obj)
            
        
         %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)
            
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [...
                {obj.condition}; obj.condition.getAllLustreExpr();...
                {obj.thenExpr}; obj.thenExpr.getAllLustreExpr();...
                {obj.ElseExpr}; obj.ElseExpr.getAllLustreExpr()];
        end
        
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)
        
        %% This functions are used for ForIterator block
       [new_obj, varIds] = changePre2Var(obj)
         new_obj = changeArrowExp(obj, cond)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            vcondId = obj.condition.GetVarIds();
            thenCondId = obj.thenExpr.GetVarIds();
            elseCondId = obj.ElseExpr.GetVarIds();
            varIds = [vcondId, thenCondId, elseCondId];
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
         [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
         
        [new_obj, outputs_map] = pseudoCode2Lustre_OnlyElseExp(obj, outputs_map, old_outputs_map)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.condition);
            addNodes(obj.thenExpr);
            addNodes(obj.ElseExpr);
        end
        
        
        
        %%
        code = print(obj, backend)
        
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    methods(Static)
        % This function return the IteExpr object
        % representing nested if-else.
        exp = nestedIteExpr(conds, thens)
        
        [conds, thens] = getCondsThens(exp)
    end
end

