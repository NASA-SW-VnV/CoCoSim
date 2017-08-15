classdef Composition
    %Composition A component content Composition is either an Or(Transition,sl) state with initializing
    %transitions Transition and sub-states sl, or an And(sl) state where all sl
    %sub-states are run in parallel.
    
    properties
        type;
        tinit;
        substates;
    end
    
    methods(Static = true)
        function obj = Composition(t, tinit, sl)
            obj.type = t;
            obj.tinit = tinit;
            obj.substates = sl;
        end
        
        function c_obj = create_object(state)
            t = state.Decomposition;
            default_transitions = SFIRUtils.sort_transitions(state.find('-isa',...
                'Stateflow.Transition','-and', 'Source', '',  '-depth', 1));
            t_init = [];
            for i=1:numel(default_transitions)
                t_init = [t_init; Transition.create_object(default_transitions(i))];
            end
            sub_states = state.find('-isa','Stateflow.State');
            substates_names = {};
            for i=1:numel(sub_states)
                substates_names{i} = sub_states(i).Name;
            end
            c_obj = Composition(t, t_init, substates_names);
        end
    end
    
end

