classdef MergeExpr < nasa_toLustre.lustreAst.LustreExpr
    %MergeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        clock;%LusID
        exprs;
    end
    
    methods
        function obj = MergeExpr(clock, exprs)
            obj.clock = clock;
            if iscell(exprs)
                obj.exprs = exprs;
            else
                obj.exprs{1} = exprs;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_exprs = cellfun(@(x) x.deepCopy(), obj.exprs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_exprs = cellfun(@(x) x.simplify(), obj.exprs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.exprs, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %% substituteVars
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_exprs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.exprs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {obj.clock};
            for i=1:numel(obj.exprs)
                all_obj = [all_obj; {obj.exprs{i}}; obj.exprs{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_exprs = {};
            for i=1:numel(obj.exprs)
                [new_exprs{i}, varIds_i] = obj.exprs{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_exprs = cellfun(@(x) x.changeArrowExp(cond), obj.exprs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.clock.GetVarIds();
            for i=1:numel(obj.exprs)
                varIds_i = obj.exprs{i}.GetVarIds();
                varIds = [varIds, varIds_i];
            end
        end
         % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_exprs = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
                obj.exprs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.exprs);
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            exprs_cell = cellfun(@(x) sprintf('(%s)', x.print(backend)),...
                obj.exprs, 'UniformOutput', 0);
            exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
            
            code = sprintf('(merge %s\n\t\t %s)', obj.clock.print(backend), exprs_str);
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
    
end

