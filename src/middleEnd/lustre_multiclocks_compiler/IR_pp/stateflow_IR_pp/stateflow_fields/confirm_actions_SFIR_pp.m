function [ new_ir, status ] = confirm_actions_SFIR_pp( new_ir )
    %confirm_actions_SFIR_pp asks the user to confirm if we parsed actions
    %correctly, if not we update them by the user input.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global CHECK_SF_ACTIONS;
    status = 0;
    if ~isempty(CHECK_SF_ACTIONS) && CHECK_SF_ACTIONS == 0
        return;
    end
    
    new_ir.States = adapt_states(new_ir.States);
    
    for i=1:numel(new_ir.States)
        statePath = new_ir.States{i}.Path;
        % default transition
        new_ir.States{i}.Composition.DefaultTransitions= ...
            adapt_transitions(new_ir.States{i}.Composition.DefaultTransitions, statePath, 'Default');
        
        %OuterTransitions
        new_ir.States{i}.OuterTransitions = ...
            adapt_transitions(new_ir.States{i}.OuterTransitions, statePath, 'Outer');
        
        %InnerTransitions
        new_ir.States{i}.InnerTransitions= ...
            adapt_transitions(new_ir.States{i}.InnerTransitions, statePath, 'Inner');
        
    end
    
    
    for i=1:numel(new_ir.Junctions)
        junctionPath = new_ir.Junctions{i}.Path;
        new_ir.Junctions{i}.OuterTransitions = ...
            adapt_transitions(new_ir.Junctions{i}.OuterTransitions, junctionPath, 'Default');
    end
    %
    for i=1:numel(new_ir.GraphicalFunctions)
        new_ir.GraphicalFunctions{i} = confirm_actions_SFIR_pp( new_ir.GraphicalFunctions{i} );
    end
    
end
function states = adapt_states(states)
    states_keywords = {'en', 'du', 'ex'};
    states_fields = {'Entry', 'During', 'Exit'};
    % 'Bind', 'On', 'OnAfter', ...
    %     'OnBefore', 'OnAt', 'OnEvery'};
    for i=1:numel(states)
        statePath = states{i}.Path;
        if isfield(states{i}, 'LabelString')...
                && ( contains(states{i}.LabelString, ':') ...
                || contains(states{i}.LabelString, ';')  ...%the case of one action without (en:|entry:) prefix
                || contains(states{i}.LabelString, '='))
            display_msg(...
                sprintf('We need your confirmation on state actions of the State\n %s:', ...
                statePath),...
                MsgType.INFO, 'confirm_actions', '');
            display_msg(...
                sprintf('The original StateLabel is :\n %s', ...
                states{i}.LabelString),...
                MsgType.INFO, 'confirm_actions', '');
            
            for j=1:numel(states_fields)
                f = states_fields{j};
                if isfield(states{i}.Actions, f) ...
                        && contains(states{i}.LabelString, states_keywords{j})
                    if isempty(states{i}.Actions.(f))
                        action = 'not defined';
                    else
                        action = states{i}.Actions.(f);
                        if iscell(action)
                            action = MatlabUtils.strjoin(action, '\n');
                        end
                    end
                    display_msg(...
                        sprintf('We assumed "%s" action is : %s',f, action),...
                        MsgType.INFO, 'confirm_actions', '');
                end
            end
            prompt = 'Are all the above actions correct? Y/N [Y]: ';
            str = input(prompt,'s');
            if ~isempty(str) && isequal(upper(str), 'N')
                for j=1:numel(states_fields)
                    f = states_fields{j};
                    if isfield(states{i}.Actions, f) ...
                            && contains(states{i}.LabelString, states_keywords{j})
                        prompt = sprintf('Provide the correct %s action (hit enter if not required):', f);
                        str = input(prompt,'s');
                        if ~isempty(str)
                            states{i}.Actions.(f) = str;
                        end
                    end
                end
            end
        end
    end
end
function transitions = adapt_transitions(transitions, statePath, transitionType)
    action_fields = {'Event', 'Condition', 'ConditionAction', 'TransitionAction'};
    for i=1:numel(transitions)
        if isfield(transitions{i}, 'LabelString')...
                && ~isempty(transitions{i}.LabelString) ...
                && ~isequal(transitions{i}.LabelString, '?')
            display_msg(...
                sprintf('We need your confirmation on %s transition number %d of the State\n %s:', ...
                transitionType, transitions{i}.ExecutionOrder, statePath),...
                MsgType.INFO, 'confirm_actions', '');
            display_msg(...
                sprintf('The original Transition label is :\n %s', ...
                transitions{i}.LabelString),...
                MsgType.INFO, 'confirm_actions', '');
            
            for j=1:numel(action_fields)
                f = action_fields{j};
                if isfield(transitions{i}, f)
                    if isempty(transitions{i}.(f))
                        action = 'not defined';
                    else
                        action = transitions{i}.(f);
                        if iscell(action)
                            action = MatlabUtils.strjoin(action, '\n');
                        end
                    end
                    display_msg(...
                        sprintf('We assumed "%s" of the transition is : %s',f, action),...
                        MsgType.INFO, 'confirm_actions', '');
                end
            end
            prompt = 'Are all the above parts correct? Y/N [Y]: ';
            str = input(prompt,'s');
            if ~isempty(str) && isequal(upper(str), 'N')
                for j=1:numel(action_fields)
                    f = action_fields{j};
                    if isfield(transitions{i}, f)
                        prompt = sprintf('Provide the correct %s (hit enter if not required):', f);
                        str = input(prompt,'s');
                        if ~isempty(str)
                            transitions{i}.(f) = str;
                        end
                    end
                end
            end
        end
    end
end
