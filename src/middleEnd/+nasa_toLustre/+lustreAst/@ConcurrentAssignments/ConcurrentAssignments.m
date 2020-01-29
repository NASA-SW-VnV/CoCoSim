classdef ConcurrentAssignments < nasa_toLustre.lustreAst.LustreExpr
    %ConcurrentAssignments: a set of Lustre eqts, it is only used in Stateflow for
    %Pseudo Lustre code.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
        assignments;
    end
    
    methods
        function obj = ConcurrentAssignments(assignments)
            if ~iscell(assignments)
                obj.assignments{1} = assignments;
            else
                obj.assignments = assignments;
            end
        end
        
        function assignments = getAssignments(obj)
            assignments = obj.assignments;
        end
        function  setAssignments(obj, assignments)
            if ~iscell(assignments)
                obj.assignments{1} = assignments;
            else
                obj.assignments = assignments;
            end
        end
        
        %% deepcopy
        new_obj = deepCopy(obj)

        %% simplify expression
        new_obj = simplify(obj)

        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(obj, var)

        %% substituteVars
        substituteVars(obj, oldVar, newVar)

        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.assignments)
                all_obj = [all_obj; {obj.assignments{i}}; obj.assignments{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        
        new_obj = changeArrowExp(obj, cond)

        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.assignments)
                varIds = [varIds, obj.assignments{i}.GetVarIds()];
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
            addNodes(obj.assignments);
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

