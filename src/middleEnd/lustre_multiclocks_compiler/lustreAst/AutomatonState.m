classdef AutomatonState < LustreExpr
    %AutomatonState
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        local_vars;
        strongTrans;
        weakTrans;
        body;
    end
    
    methods
        function obj = AutomatonState(name, local_vars, strongTrans, weakTrans, body)
            obj.name = name;
            if ~iscell(local_vars)
                obj.local_vars{1} = local_vars;
            else
                obj.local_vars = local_vars;
            end
            if ~iscell(strongTrans)
                obj.strongTrans{1} = strongTrans;
            else
                obj.strongTrans = strongTrans;
            end
            if ~iscell(weakTrans)
                obj.weakTrans{1} = weakTrans;
            else
                obj.weakTrans = weakTrans;
            end
            if ~iscell(body)
                obj.body{1} = body;
            else
                obj.body = body;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_local_vars = cellfun(@(x) x.deepCopy(), obj.local_vars, 'UniformOutput', 0);
            
            new_strongTrans = cellfun(@(x) x.deepCopy(), obj.strongTrans, 'UniformOutput', 0);
            
            new_weakTrans = cellfun(@(x) x.deepCopy(), obj.weakTrans, 'UniformOutput', 0);
            
            new_body = cellfun(@(x) x.deepCopy(), obj.body, 'UniformOutput', 0);
            
            new_obj = AutomatonState(obj.name, new_local_vars, ...
                new_strongTrans, new_weakTrans, new_body);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            %TODO: Not done for this class yet, as it is not used by stateflow.
            new_obj = obj;
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
                
            end
            addNodes(obj.strongTrans);
            addNodes(obj.weakTrans);
            addNodes(obj.body);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_local_vars = cellfun(@(x) x.simplify(), obj.local_vars, 'UniformOutput', 0);
            
            new_strongTrans = cellfun(@(x) x.simplify(), obj.strongTrans, 'UniformOutput', 0);
            
            new_weakTrans = cellfun(@(x) x.simplify(), obj.weakTrans, 'UniformOutput', 0);
            
            new_body = cellfun(@(x) x.simplify(), obj.body, 'UniformOutput', 0);
            
            new_obj = AutomatonState(obj.name, new_local_vars, ...
                new_strongTrans, new_weakTrans, new_body);
        end
         %% nbOccuranceVar ignored in Automaton
        function nb_occ = nbOccuranceVar(varargin)
            nb_occ = 0;
        end
        %% substituteVars ignored in Automaton
        function new_obj = substituteVars(obj, varargin)
            new_obj = obj;
        end
        %%
        function code = print(obj, backend)
            %TODO: check if lustrec syntax is OK for jkind and prelude.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            lines = {};
            lines{1} = sprintf('\tstate %s:\n', obj.name);
            % Strong transition
            for i=1:numel(obj.strongTrans)
                lines{end+1} = sprintf('\tunless %s', ...
                    obj.strongTrans{i}.print(backend));
            end
            %local variables
            if ~isempty(obj.local_vars)
                lines{end + 1} = sprintf('var %s\n', ...
                    LustreAst.listVarsWithDT(obj.local_vars, backend));
            end
            % body
            lines{end+1} = sprintf('\tlet\n');
            for i=1:numel(obj.body)
                lines{end+1} = sprintf('\t\t%s\n', ...
                    obj.body{i}.print(backend));
            end
            lines{end+1} = sprintf('\ttel\n');
            % weak transition
            for i=1:numel(obj.weakTrans)
                lines{end+1} = sprintf('\tuntil %s\n', ...
                    obj.weakTrans{i}.print(backend));
            end
            code = MatlabUtils.strjoin(lines, '');
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

