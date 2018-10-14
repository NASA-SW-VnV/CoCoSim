classdef EveryExpr < LustreExpr
    %EveryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        nodeArgs;
        cond;
    end
    
    methods
        function obj = EveryExpr(nodeName, nodeArgs, cond)
            obj.nodeName = nodeName;
            obj.nodeArgs = nodeArgs;
            obj.cond = cond;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.nodeArgs)
                new_args = cellfun(@(x) x.deepCopy(), obj.nodeArgs, 'UniformOutput', 0);
            else
                new_args = obj.nodeArgs.deepCopy();
            end
            new_obj = EveryExpr(obj.nodeName, ...
                new_args, obj.cond.deepCopy());
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            if iscell(obj.nodeArgs)
                new_exprs = {};
                for i=1:numel(obj.nodeArgs)
                    [new_exprs{i}, varIds_i] = obj.nodeArgs{i}.changePre2Var();
                    varIds = [varIds, varIds_i];
                end
            else
                [new_exprs, varIds] = obj.nodeArgs.changePre2Var();
            end
            [condE, varId] = obj.cond.changePre2Var();
            varIds = [varIds, varId];
            new_obj = EveryExpr(obj.nodeName, ...
                new_exprs, condE);
        end
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.nodeArgs)
                new_args = cellfun(@(x) x.changeArrowExp(cond), obj.nodeArgs, 'UniformOutput', 0);
            else
                new_args = obj.nodeArgs.changeArrowExp(cond);
            end
            new_obj = EveryExpr(obj.nodeName, ...
                new_args, obj.cond.changeArrowExp(cond));
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            if iscell(obj.nodeArgs)
                for i=1:numel(obj.nodeArgs)
                    varIds_i = obj.nodeArgs{i}.GetVarIds();
                    varIds = [varIds, varIds_i];
                end
            else
                varIds = obj.nodeArgs.GetVarIds();
            end
            varId = obj.cond.GetVarIds();
            varIds = [varIds, varId];
        end
        %%
        function code = print(obj, backend)
            if BackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                %TODO: check if LUSTREC syntax is OK for the other backends.
                code = obj.print_lustrec(backend);
            end
        end
        
        function code = print_lustrec(obj, backend)
            args_str = NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(%s(%s) every %s)', ...
                obj.nodeName, ...
                args_str,...
                obj.cond.print(backend));
        end
        
        function code = print_kind2(obj, backend)
            args_str = NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(restart %s every %s)(%s)', ...
                obj.nodeName, ...
                obj.cond.print(backend),...
                args_str);
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

