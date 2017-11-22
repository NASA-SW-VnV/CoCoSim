classdef Junction
    %Junction is defined by a list of Transition (transitions)
    properties
        path;
        type;
        outer_trans;
    end
    
    methods(Static = true)
        function obj = Junction(path, type, To)
            obj.path = path;
            obj.type = type;
            obj.outer_trans = To;
        end
        
        function j_obj = create_object(chart, j)
            To = Junction.get_transitions(chart, j);
            j_type = j.Type;
            fullpath = fullfile(j.Path, strcat('Junction',num2str(j.Id)));
            j_obj = Junction(fullpath, j_type, To);
        end
        
        %% Get outer transitions
        function [To] = get_transitions(chart, s)
            outer_transitions = SFIRUtils.sort_transitions(chart.find('-isa', 'Stateflow.Transition', '-and', 'Source', s));
            To = [];
            for i=1:numel(outer_transitions)
                To = [To; Transition.create_object(outer_transitions(i))];
            end
        end
        
       
    end
    
end

