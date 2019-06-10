classdef IteExpr < nasa_toLustre.lustreAst.LustreExpr
    %IteExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
        
        function [body, vars] = binarySearch(table_elem, idxVar, outName,...
                outDT, sortedIndices, body, vars, origName)
            % generate binary search code for searching a table
            if nargin < 5 || isempty(sortedIndices)
                sortedIndices = (1:length(table_elem));
            end
            if nargin < 6
                body = {};
            end
            if nargin < 7
                vars = {};
            end
            if nargin < 8
                origName = outName;
            end
            if length(sortedIndices) <= 10
                % do a nomral loop
                conds = cell(1,length(sortedIndices)-1);
                thens = cell(1,length(sortedIndices));
                for j=1:length(sortedIndices)-1
                    idx = sortedIndices(j);
                    conds{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                        idxVar, nasa_toLustre.lustreAst.IntExpr(idx));
                    thens{j} = table_elem{idx};
                end
                thens{end} = table_elem{sortedIndices(end)};
                rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                    nasa_toLustre.lustreAst.VarIdExpr(outName), rhs);
                vars{end+1} = nasa_toLustre.lustreAst.LustreVar(outName, outDT);
            else
                idxMin = sortedIndices(1);
                idxMax = sortedIndices(end);
                mid_value = ceil((idxMin + idxMax)/2);
                conds = cell(1, 2);
                thens = cell(1, 3);
                conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                    idxVar, nasa_toLustre.lustreAst.IntExpr(mid_value));
                thens{1} = table_elem{mid_value};
                
                conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.GT,...
                    idxVar, nasa_toLustre.lustreAst.IntExpr(mid_value));
                outMaxName = sprintf('%s__FromIdx%d_ToIdx%d', origName, mid_value+1, idxMax);
                thens{2} = nasa_toLustre.lustreAst.VarIdExpr(outMaxName);
                newIndices = (mid_value+1:idxMax);
                [body, vars] = nasa_toLustre.lustreAst.IteExpr.binarySearch(...
                    table_elem, idxVar, outMaxName,...
                    outDT, newIndices, body, vars, origName);
                
                outMinName = sprintf('%s__FromIdx%d_ToIdx%d', origName, idxMin, mid_value-1);
                thens{3} = nasa_toLustre.lustreAst.VarIdExpr(outMinName);
                newIndices = (idxMin:mid_value -1);
                [body, vars] = nasa_toLustre.lustreAst.IteExpr.binarySearch(...
                    table_elem, idxVar, outMinName,...
                    outDT, newIndices, body, vars, origName);
                
                rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                    nasa_toLustre.lustreAst.VarIdExpr(outName), rhs);
                vars{end+1} = nasa_toLustre.lustreAst.LustreVar(outName, outDT);
            end
        end
    end
end

