classdef ActivateExpr < nasa_toLustre.lustreAst.LustreExpr
    %ActivateExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        nodeArgs;
        activate_cond;
        has_restart;
        restart_cond;
    end
    
    methods
        function obj = ActivateExpr(nodeName, nodeArgs, activate_cond,...
                has_restart, restart_cond)
            obj.nodeName = nodeName;
            if ~iscell(nodeArgs)
                obj.nodeArgs{1} = nodeArgs;
            else
                obj.nodeArgs = nodeArgs;
            end
            obj.activate_cond = activate_cond;
            if nargin < 4
                obj.has_restart = false;
            else
                obj.has_restart = has_restart;
            end
            if nargin < 5
                obj.restart_cond = {};
            else
                obj.restart_cond = restart_cond;
            end    
        end
        
        function nodeName = getNodeName(obj)
            nodeName = obj.nodeName;
        end
        function nodeArgs = getNodeArgs(obj)
            nodeArgs = obj.nodeArgs;
        end
        function activate_cond = getActivateCond(obj)
            activate_cond = obj.activate_cond;
        end
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        
        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.activate_cond}; obj.activate_cond.getAllLustreExpr()];
            for i=1:numel(obj.nodeArgs)
                all_obj = [all_obj; {obj.nodeArgs{i}}; obj.nodeArgs{i}.getAllLustreExpr()];
            end
            if obj.has_restart
                all_obj = [{obj.restart_cond}; obj.restart_cond.getAllLustreExpr()];
            end
        end
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, activate_cond)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.nodeArgs)
                varIds_i = obj.nodeArgs{i}.GetVarIds();
                varIds = [varIds, varIds_i];
            end
            varIds = [varIds, obj.activate_cond.GetVarIds()];
            if obj.has_restart
                varIds = [varIds, obj.restart_cond.GetVarIds()];
            end
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
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
            addNodes(obj.activate_cond);
            if obj.has_restart
                addNodes(obj.restart_cond);
            end
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

