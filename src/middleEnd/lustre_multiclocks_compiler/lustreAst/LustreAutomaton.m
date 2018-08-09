classdef LustreAutomaton < LustreExpr
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
            obj.states = states;
        end
        
        function new_obj = deepCopy(obj)
            new_states = cell(1, numel(obj.states));
            for i=1:numel(obj.states)
                new_states{i} = obj.states{i}.deepCopy();
            end
            new_obj = LustreAutomaton(obj.name,...
                new_states);
        end
        
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

