classdef Program
    %PROGRAM (s, src_i list) is composed of state definitions s:sd and
    %junctions j:T, with a main node s. 
    
    properties
        name;
        states;
        junctions;
    end
    
    methods(Static = true)
        function obj = Program(main, states, junc)
            obj.name = main;
            obj.states = states;
            obj.junctions = junc;
        end
        
        function states = get_all_states(chart)
            states = [];
            states_1 = chart.findShallow('State');
            for i=1:numel(states_1)
                states = [ Program.get_all_states(states_1(i)); states_1(i); states ];
            end
        end
    end
    
end

