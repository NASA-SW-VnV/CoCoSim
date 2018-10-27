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
            if iscell(exprs)
                obj.exprs = exprs;
            else
                obj.exprs{1} = exprs;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_exprs = cellfun(@(x) x.deepCopy(), obj.exprs, 'UniformOutput', 0);
            
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_exprs = {};
            for i=1:numel(obj.exprs)
                [new_exprs{i}, varIds_i] = obj.exprs{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_exprs = cellfun(@(x) x.changeArrowExp(cond), obj.exprs, 'UniformOutput', 0);
            
            new_obj = MergeExpr(obj.clock, new_exprs);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.exprs)
                varIds_i = obj.exprs{i}.GetVarIds();
                varIds = [varIds, varIds_i];
            end
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

