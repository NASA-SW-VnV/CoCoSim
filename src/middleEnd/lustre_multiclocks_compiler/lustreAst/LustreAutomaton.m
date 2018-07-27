classdef LustreAutomaton < LustreExpr
    %LustreAutomaton
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;
        states
    end
    
    methods 
        function obj = LustreAutomaton(name, states)
            obj.name = name;
            obj.states = states;
        end
        
        function code = print_lustrec(obj)
            lines = {};
            lines{1} = sprintf('\tautomaton %s\n', obj.name.print_lustre());
            % Strong transition
            for i=1:numel(obj.states)
                lines{end+1} = sprintf('%s\n', ...
                        obj.states{i}.print_lustre());
            end
            code = MatlabUtils.strjoin(lines, '');
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end
    end

end

