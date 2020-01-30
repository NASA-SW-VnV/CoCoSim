%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef IteExpr < nasa_toLustre.lustreAst.LustreExpr
    %IteExpr

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
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        
        [new_obj, outputs_map] = pseudoCode2Lustre_OnlyElseExp(obj, outputs_map, old_outputs_map, node, data_map)
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

