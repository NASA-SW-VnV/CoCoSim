classdef State_def
    %SD State definition sd::=((a_e, a_d, a_x), T_o, T_i, C). A single state
    %is defined by the entry, during and exit actions (a_e, a_d, a_x),
    %outer and inner transitions T_o and T_i, as well as component content
    %C.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        path;
        state_actions;
        outer_trans;
        inner_trans;
        internal_composition;
    end
    
    methods(Static = true)
        function obj = State_def(path, actions, To, Ti, Comp)
            obj.path = path;
            obj.state_actions = actions;
            obj.outer_trans = To;
            obj.inner_trans = Ti;
            obj.internal_composition = Comp;
        end
        
        function s_obj = create_object(chart, s)
            state_label = s.get('LabelString');
            state_actions = State_def.extract_state_actions(state_label);
            [To, Ti] = State_def.get_transitions(chart, s);
            comp = Composition.create_object(s);
            fullpath = fullfile(s.Path, s.Name);
            s_obj = State_def(fullpath, state_actions, To, Ti, comp);
        end
        %% extract state actions from the label
        function state_actions = extract_state_actions(label)
            % remove comments and "..." key word for long actions
            expression = '(\.{3}|/\*(\s*\w*\W*\s*)*\*/)';
            replace = '';
            label = regexprep(label,expression,replace);
            
            %split the label
            expr = '(en(try)?|ex(it)?|du(ring)?)\s*:';
            actions = regexp(label, expr, 'split');
            actions_name = regexp(label, expr, 'tokens');
            n = numel(actions_name);
            action_map = containers.Map();
            for i=1:n
                if isKey(action_map, actions_name{i})
                    last = action_map(char(actions_name{i}));
                else
                    last = '';
                end
                action_map(char(actions_name{i})) = [last, actions{i+1}];
            end
            en = ''; du = ''; ex = '';
            
            if isKey(action_map, 'en')
                en = action_map('en');
            end
            if isKey(action_map, 'entry')
                en = [en, action_map('entry')];
            end
            if isKey(action_map, 'du')
                du = action_map('du');
            end
            if isKey(action_map, 'during')
                du = [du, action_map('during')];
            end
            if isKey(action_map, 'ex')
                ex = action_map('ex');
            end
            if isKey(action_map, 'exit')
                ex = [ex, action_map('exit')];
            end
            
            state_actions.entry = SFIRUtils.split_actions(en);
            state_actions.during = SFIRUtils.split_actions(du);
            state_actions.exit = SFIRUtils.split_actions(ex);
            
        end
        
        %% Get outer transitions
        function [To, Ti] = get_transitions(chart, s)
            outer_transitions = SFIRUtils.sort_transitions(chart.find('-isa', 'Stateflow.Transition', '-and', 'Source', s));
            inner_transitions = SFIRUtils.sort_transitions(s.innerTransitions());
            outer_transitions = setdiff(outer_transitions,inner_transitions);
            
            To = []; Ti =[];
            for i=1:numel(outer_transitions)
                To = [To; Transition.create_object(outer_transitions(i))];
            end
            for i=1:numel(inner_transitions)
                Ti = [Ti; Transition.create_object(inner_transitions(i))];
            end
        end
        
        
    end
    
end

