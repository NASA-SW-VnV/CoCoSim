classdef MergeExpr < LustreExpr
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
            obj.exprs = exprs;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.exprs)
                new_exprs = cellfun(@(x) x.deepCopy(), obj.exprs, 'UniformOutput', 0);
            else
                new_exprs = obj.exprs.deepCopy();
            end
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            if iscell(obj.exprs)
                new_exprs = {};
                for i=1:numel(obj.exprs)
                    [new_exprs{i}, varIds_i] = obj.exprs{i}.changePre2Var();
                    varIds = [varIds, varIds_i];
                end
            else
                [new_exprs, varIds] = obj.exprs.changePre2Var();
            end
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.exprs)
                new_exprs = cellfun(@(x) x.changeArrowExp(cond), obj.exprs, 'UniformOutput', 0);
            else
                new_exprs = obj.exprs.changeArrowExp(cond);
            end
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            if iscell(obj.exprs)
                for i=1:numel(obj.exprs)
                    varIds_i = obj.exprs{i}.GetVarIds();
                    varIds = [varIds, varIds_i];
                end
            else
                varIds = obj.exprs.GetVarIds();
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
            addNodes(obj.exprs);
        end
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            if iscell(obj.exprs)
                exprs_cell = cellfun(@(x) sprintf('(%s)', x.print(backend)),...
                    obj.exprs, 'UniformOutput', 0);
                exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
            else
                exprs_str = obj.exprs.print(backend);
            end
            code = sprintf('(merge %s\n\t\t %s)', obj.clock.print(backend), exprs_str);
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

