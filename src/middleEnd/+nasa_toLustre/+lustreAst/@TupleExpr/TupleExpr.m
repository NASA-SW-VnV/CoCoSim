classdef TupleExpr < nasa_toLustre.lustreAst.LustreExpr
    %TupleExpr: e.g. (false, true, false)

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
        
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(obj, var)
        %% substituteVars
        new_obj = substituteVars(obj, var, newVar)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.args)
                all_obj = [all_obj; {obj.args{i}}; obj.args{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, cond)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.args)
                varIds = [varIds, obj.args{i}.GetVarIds()];
            end
            
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
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
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

