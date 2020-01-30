classdef NodeCallExpr < nasa_toLustre.lustreAst.LustreExpr
    %NodeCallExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        args;
    end
    
    methods
        function obj = NodeCallExpr(nodeName, args)
            obj.nodeName = nodeName;
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
        function name = getNodeName(obj)
            name = obj.nodeName;
        end
        
        %%
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
                varIds_i = obj.args{i}.GetVarIds();
                varIds = [varIds, varIds_i];
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
            nodesCalled{end+1} = obj.nodeName;
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
        args_str = getArgsStr(args, backend)
    end
end

