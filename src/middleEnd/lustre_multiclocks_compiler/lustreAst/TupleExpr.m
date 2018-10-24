classdef TupleExpr < LustreExpr
    %TupleExpr: e.g. (false, true, false)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        args;
    end
    
    methods
        function obj = TupleExpr(args)
            obj.args = args;
        end
        
        function args = getArgs(obj)
            args = obj.args;
        end
        function  setArgs(obj, arg)
            obj.args = arg;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.args)
                new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
            else
                new_args = obj.args.deepCopy();
            end
            new_obj = TupleExpr(new_args);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            if iscell(obj.args)
                new_args = {};
                for i=1:numel(obj.args)
                    [new_args{i}, varIds_i] = obj.args{i}.changePre2Var();
                    varIds = [varIds, varIds_i];
                end
            else
                [new_args, varIds] = obj.args.changePre2Var();
            end
            new_obj = TupleExpr(new_args);
            
        end
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.args)
                new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
            else
                new_args = obj.args.changeArrowExp(cond);
            end
            new_obj = TupleExpr(new_args);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            if iscell(obj.args)
                for i=1:numel(obj.args)
                    varIds_i = obj.args{i}.GetVarIds();
                    varIds = [varIds, varIds_i];
                end
            else
                varIds = obj.args.GetVarIds();
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
            addNodes(obj.args);
        end
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            code = sprintf('(%s)', ...
                NodeCallExpr.getArgsStr(obj.args, backend));
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

