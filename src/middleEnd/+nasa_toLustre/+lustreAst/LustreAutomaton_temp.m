classdef LustreAutomaton < nasa_toLustre.lustreAst.LustreExpr
    %LustreAutomaton
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        states
    end
    
    methods
        function obj = LustreAutomaton(name, states)
            obj.name = name;
            if iscell(states)
                obj.states = states;
            else
                obj.states{1} = states;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_states = cell(1, numel(obj.states));
            for i=1:numel(obj.states)
                new_states{i} = obj.states{i}.deepCopy();
            end
            new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
                new_states);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_states = cell(1, numel(obj.states));
            for i=1:numel(obj.states)
                new_states{i} = obj.states{i}.simplify();
            end
            new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
                new_states);
        end
        %% nbOccuranceVar ignored in Automaton
        function nb_occ = nbOccuranceVar(varargin)
            nb_occ = 0;
        end
        %% substituteVars ignored in Automaton
        function obj = substituteVars(obj, varargin)
            new_obj = obj;
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.states)
                all_obj = [all_obj; {obj.states{i}}; obj.states{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_states = cell(1, numel(obj.states));
            for i=1:numel(obj.states)
                new_states{i} = obj.states{i}.changeArrowExp(cond);
            end
            new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
                new_states);
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.states);
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            %TODO: Not done for this class yet, as it is not used by stateflow.
            new_obj = obj;
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            lines = {};
            lines{1} = sprintf('automaton %s\n', obj.name);
            % Strong transition
            for i=1:numel(obj.states)
                lines{end+1} = sprintf('%s\n', ...
                    obj.states{i}.print(backend));
            end
            code = MatlabUtils.strjoin(lines, '');
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

