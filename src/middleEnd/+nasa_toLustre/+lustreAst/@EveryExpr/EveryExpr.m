classdef EveryExpr < nasa_toLustre.lustreAst.LustreExpr
    %EveryExpr

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
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        
        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.cond}; obj.cond.getAllLustreExpr()];
            for i=1:numel(obj.nodeArgs)
                all_obj = [all_obj; {obj.nodeArgs{i}}; obj.nodeArgs{i}.getAllLustreExpr()];
            end
        end
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, cond)
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
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
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
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj, backend)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

