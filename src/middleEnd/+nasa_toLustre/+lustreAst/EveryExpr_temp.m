classdef EveryExpr < nasa_toLustre.lustreAst.LustreExpr
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
            if ~iscell(nodeArgs)
                obj.nodeArgs{1} = nodeArgs;
            else
                obj.nodeArgs = nodeArgs;
            end
            obj.cond = cond;
        end
        
        function nodeName = getNodeName(obj)
            nodeName = obj.nodeName;
        end
        function nodeArgs = getNodeArgs(obj)
            nodeArgs = obj.nodeArgs;
        end
        function cond = getCond(obj)
            cond = obj.cond;
        end
        function new_obj = deepCopy(obj)
            new_args = cellfun(@(x) x.deepCopy(), obj.nodeArgs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_args, obj.cond.deepCopy());
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_args = cellfun(@(x) x.simplify(), obj.nodeArgs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_args, obj.cond.simplify());
        end
        
        %% substituteVars 
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_args = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.nodeArgs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_args, obj.cond);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.cond}; obj.cond.getAllLustreExpr()];
            for i=1:numel(obj.nodeArgs)
                all_obj = [all_obj; {obj.nodeArgs{i}}; obj.nodeArgs{i}.getAllLustreExpr()];
            end
        end
        %% nbOccurance
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.nodeArgs, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_exprs = {};
            for i=1:numel(obj.nodeArgs)
                [new_exprs{i}, varIds_i] = obj.nodeArgs{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            [condE, varId] = obj.cond.changePre2Var();
            varIds = [varIds, varId];
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_exprs, condE);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_args = cellfun(@(x) x.changeArrowExp(cond), obj.nodeArgs, 'UniformOutput', 0);
            
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_args, obj.cond.changeArrowExp(cond));
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.nodeArgs)
                varIds_i = obj.nodeArgs{i}.GetVarIds();
                varIds = [varIds, varIds_i];
            end
            varId = obj.cond.GetVarIds();
            varIds = [varIds, varId];
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
                obj.nodeArgs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
                new_args, obj.cond);
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
            addNodes(obj.nodeArgs);
            addNodes(obj.cond);
            nodesCalled{end+1} = obj.nodeName;
        end
        
        
        
        
        %%
        function code = print(obj, backend)
            if LusBackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                %TODO: check if LUSTREC syntax is OK for the other backends.
                code = obj.print_lustrec(backend);
            end
        end
        
        function code = print_lustrec(obj, backend)
            args_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(%s(%s) every %s)', ...
                obj.nodeName, ...
                args_str,...
                obj.cond.print(backend));
        end
        
        function code = print_kind2(obj, backend)
            args_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(restart %s every %s)(%s)', ...
                obj.nodeName, ...
                obj.cond.print(backend),...
                args_str);
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

