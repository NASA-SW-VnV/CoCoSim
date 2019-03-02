classdef ConcurrentAssignments < nasa_toLustre.lustreAst.LustreExpr
    %ConcurrentAssignments: a set of Lustre eqts, it is only used in Stateflow for
    %Pseudo Lustre code.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
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
        function new_obj = deepCopy(obj)
            new_assignments = cellfun(@(x) x.deepCopy(), obj.assignments, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_assignments = cellfun(@(x) x.simplify(), obj.assignments, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.assignments, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %% substituteVars
        function obj = substituteVars(obj, oldVar, newVar)
            new_assignments = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.assignments, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.assignments)
                all_obj = [all_obj; {obj.assignments{i}}; obj.assignments{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_assignments = cell(numel(obj.assignments), 1);
            for i=1:numel(obj.assignments)
                [new_assignments{i}, varIds_i] = obj.assignments{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_assignments = cellfun(@(x) x.changeArrowExp(cond), obj.assignments, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.assignments)
                varIds = [varIds, obj.assignments{i}.GetVarIds()];
            end
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            old_outputs_map = containers.Map(outputs_map.keys, outputs_map.values);
            new_assignments = cell(numel(obj.assignments), 1);
            for i=1:numel(obj.assignments)
                if isa(obj.assignments{i}, 'nasa_toLustre.lustreAst.LustreEq')
                    
                    if isa(obj.assignments{i}.getRhs(), 'nasa_toLustre.lustreAst.IteExpr')
                        [rhs, ~] = ...
                            obj.assignments{i}.getRhs().pseudoCode2Lustre_OnlyElseExp(...
                            outputs_map, old_outputs_map);
                    else
                        [rhs, ~] = ...
                            obj.assignments{i}.getRhs().pseudoCode2Lustre(...
                            old_outputs_map, false);
                    end
                    [lhs, outputs_map] = ...
                        obj.assignments{i}.getLhs().pseudoCode2Lustre(...
                        outputs_map, true);
                    new_assignments{i} = nasa_toLustre.lustreAst.LustreEq(lhs, rhs);
                else
                    [new_assignments{i}, outputs_map] = ...
                        obj.assignments{i}.pseudoCode2Lustre(outputs_map, isLeft);
                end
            end
            new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
        end
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
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            lines = cellfun(@(x) x.print(backend), obj.assignments, 'UniformOutput', 0);
            code = MatlabUtils.strjoin(lines, '\n\t');
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

