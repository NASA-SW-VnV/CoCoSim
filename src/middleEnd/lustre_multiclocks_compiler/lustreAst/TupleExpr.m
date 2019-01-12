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
            if ~iscell(args)
                obj.args{1} = args;
            else
                obj.args = args;
            end
        end
        
        function args = getArgs(obj)
            args = obj.args;
        end
        function  setArgs(obj, args)
            if ~iscell(args)
                obj.args{1} = args;
            else
                obj.args = args;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
            new_obj = TupleExpr(new_args);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_args = cellfun(@(x) x.simplify(), obj.args, 'UniformOutput', 0);
            % (x) => x
            if numel(new_args) == 1
                new_obj = new_args{1};
            else
                new_obj = TupleExpr(new_args);
            end
        end
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.args, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %% substituteVars
        function new_obj = substituteVars(obj, var, newVar)
            new_args = cellfun(@(x) x.substituteVars(var, newVar), obj.args, 'UniformOutput', 0);
            new_obj = TupleExpr(new_args);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_args = cell(numel(obj.args), 1);
            for i=1:numel(obj.args)
                [new_args{i}, varIds_i] = obj.args{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            
            new_obj = TupleExpr(new_args);
            
        end
        function new_obj = changeArrowExp(obj, cond)
            new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
            
            new_obj = TupleExpr(new_args);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.args)
                varIds = [varIds, obj.args{i}.GetVarIds()];
            end
            
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_args = cell(numel(obj.args), 1);
            for i=1:numel(obj.args)
                [new_args{i}, outputs_map] = ...
                    obj.args{i}.pseudoCode2Lustre(outputs_map, isLeft);
            end
            new_obj = TupleExpr(new_args);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
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

