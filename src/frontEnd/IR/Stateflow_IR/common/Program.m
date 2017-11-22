classdef Program
    %PROGRAM (s, src_i list) is composed of state definitions s:sd and
    %junctions j:T, with a main node s.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        origin_path;
        name;
        states;
        junctions;
        sffunctions;
        data;
    end
    
    methods(Static = true)
        function obj = Program(main, states, junc, sffunc, D, isSF)
            obj.origin_path = main;
            obj.name = main;
            obj.states = states;
            obj.junctions = junc;
            obj.sffunctions = sffunc;
            obj.data = D;
        end
        
        function states = get_all_states(chart)
            states = [];
            states_1 = chart.findShallow('State');
            %             states_1 = chart.find('-isa', 'Stateflow.State', '-depth', 1);
            for i=1:numel(states_1)
                states = [ Program.get_all_states(states_1(i)); states_1(i); states ];
            end
        end
        
        
        
        
    end
    
end

