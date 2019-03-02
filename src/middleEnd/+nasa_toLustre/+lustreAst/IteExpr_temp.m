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
            if exist('OneLine', 'var')
                obj.OneLine = OneLine;
            else
                obj.OneLine = false;
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
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.IteExpr(...
                obj.condition.deepCopy(),...
                obj.thenExpr.deepCopy(),...
                obj.ElseExpr.deepCopy(),...
                obj.OneLine);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            import nasa_toLustre.lustreAst.*
            new_cond = obj.condition.simplify();
            new_then = obj.thenExpr.simplify();
            new_else = obj.ElseExpr.simplify();
            % simplify trivial if-and-else
            % if true then x else y => x
            if isa(obj.condition, 'BooleanExpr')
                if obj.condition.getValue()
                    new_obj = new_then;
                else
                    new_obj = new_else;
                end
                return;
                
            end
            new_obj = nasa_toLustre.lustreAst.IteExpr(new_cond, new_then, new_else, obj.OneLine);
            
        end
        
         %% substituteVars 
        function obj = substituteVars(obj, oldVar, newVar)
            new_obj = nasa_toLustre.lustreAst.IteExpr(...
                obj.condition.substituteVars(oldVar, newVar),...
                obj.thenExpr.substituteVars(oldVar, newVar),...
                obj.ElseExpr.substituteVars(oldVar, newVar),...
                obj.OneLine);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [...
                {obj.condition}; obj.condition.getAllLustreExpr();...
                {obj.thenExpr}; obj.thenExpr.getAllLustreExpr();...
                {obj.ElseExpr}; obj.ElseExpr.getAllLustreExpr()];
        end
        
        %% nbOccurance
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.condition.nbOccuranceVar(var) ...
                + obj.thenExpr.nbOccuranceVar(var)...
                + obj.ElseExpr.nbOccuranceVar(var);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            [cond, vcondId] = obj.condition.changePre2Var();
            [then, thenCondId] = obj.thenExpr.changePre2Var();
            [elseE, elseCondId] = obj.ElseExpr.changePre2Var();
            varIds = [vcondId, thenCondId, elseCondId];
            new_obj = nasa_toLustre.lustreAst.IteExpr(cond, then, elseE, obj.OneLine);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.changeArrowExp(cond),...
                obj.thenExpr.changeArrowExp(cond),...
                obj.ElseExpr.changeArrowExp(cond),...
                obj.OneLine);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            vcondId = obj.condition.GetVarIds();
            thenCondId = obj.thenExpr.GetVarIds();
            elseCondId = obj.ElseExpr.GetVarIds();
            varIds = [vcondId, thenCondId, elseCondId];
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.pseudoCode2Lustre(outputs_map, false),...
                obj.thenExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.ElseExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.OneLine);
        end
        function [new_obj, outputs_map] = pseudoCode2Lustre_OnlyElseExp(obj, outputs_map, old_outputs_map)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.pseudoCode2Lustre(old_outputs_map, false),...
                obj.thenExpr.pseudoCode2Lustre(old_outputs_map, false),...
                obj.ElseExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.OneLine);
        end
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
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            if obj.OneLine
                code = sprintf('(if %s then %s else %s)', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            else
                code = sprintf('if %s then\n\t\t%s\n\t    else %s', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            end
            
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    methods(Static)
        % This function return the IteExpr object
        % representing nested if-else.
        function exp = nestedIteExpr(conds, thens)
            if numel(thens) ~= numel(conds) + 1
                display_msg('Number of Thens expressions should be equal to Numbers of Conds + 1',...
                    MsgType.ERROR, 'IteExpr.nestedIteExpr', '');
                exp = nasa_toLustre.lustreAst.VarIdExpr('');
                return;
            end
            if isempty(conds)
                exp = thens;
            elseif numel(conds) == 1
                if iscell(conds)
                    c = conds{1};
                else
                    c = conds;
                end
                exp = nasa_toLustre.lustreAst.IteExpr(c, thens{1}, thens{2});
            else
                exp = nasa_toLustre.lustreAst.IteExpr(conds{1}, ...
                    thens{1}, ...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr( conds(2:end), thens(2:end)) ...
                    );
            end
        end
        
        function [conds, thens] = getCondsThens(exp)
            import nasa_toLustre.lustreAst.*
            conds = {};
            thens = {};
            if isa(exp, 'ParenthesesExpr')
                exp = exp.getExp();
            end
            if ~isa(exp, 'IteExpr')
                thens{1} = exp;
                return;
            end
            
            conds{1} = exp.getCondition();
            thens{1} = exp.getThenExpr();
            elseExp = exp.getElseExpr();
            [conds_i, thens_i] = nasa_toLustre.lustreAst.IteExpr.getCondsThens(elseExp);
            conds = MatlabUtils.concat(conds, conds_i);
            thens = MatlabUtils.concat(thens, thens_i);
        end
    end
end

