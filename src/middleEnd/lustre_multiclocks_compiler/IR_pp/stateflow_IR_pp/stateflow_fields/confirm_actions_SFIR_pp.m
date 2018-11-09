function [ new_ir, status ] = confirm_actions_SFIR_pp( new_ir )
    %confirm_actions_SFIR_pp asks the user to confirm if we parsed actions
    %correctly, if not we update them by the user input.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    states_keywords = {'en', 'du', 'ex'};
    states_fields = {'Entry', 'During', 'Exit'};
    % 'Bind', 'On', 'OnAfter', ...
    %     'OnBefore', 'OnAt', 'OnEvery'};
    for i=1:numel(new_ir.States)
        statePath = new_ir.States{i}.Path;
        %State Actions
        if isfield(new_ir.States{i}, 'LabelString')...
                && ( contains(new_ir.States{i}.LabelString, ':') ...
                || contains(new_ir.States{i}.LabelString, ';')  ...%the case of one action without (en:|entry:) prefix
                || contains(new_ir.States{i}.LabelString, '='))
            display_msg(...
                sprintf('We need your confirmation on state actions of the State\n %s:', ...
                statePath),...
                MsgType.INFO, 'confirm_actions', '');
            display_msg(...
                sprintf('The original StateLabel is :\n %s', ...
                new_ir.States{i}.LabelString),...
                MsgType.INFO, 'confirm_actions', '');
            
            for j=1:numel(states_fields)
                f = states_fields{j};
                if isfield(new_ir.States{i}.Actions, f) ...
                        && contains(new_ir.States{i}.LabelString, states_keywords{j})
                    if isempty(new_ir.States{i}.Actions.(f))
                        action = 'not defined';
                    else
                        action = new_ir.States{i}.Actions.(f);
                    end
                    display_msg(...
                        sprintf('We assumed "%s" action is : %s',f, action),...
                        MsgType.INFO, 'confirm_actions', '');
                    prompt = sprintf('If the above action is correct, hit Enter.\nIf not, type the correct action then hit Enter\n(actions should be seperated by ";"): ');
                    str = input(prompt,'s');
                    if ~isempty(str)
                        new_ir.States{i}.Actions.(f) = str;
                    end
                end
            end
        end
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
                    end
                    display_msg(...
                        sprintf('We assumed "%s" of the transition is : %s',f, action),...
                        MsgType.INFO, 'confirm_actions', '');
                    prompt = sprintf('If the above is correct, hit Enter.\nIf not, type the correct action/condition/event then hit Enter\n(actions should be seperated by ";"): ');
                    str = input(prompt,'s');
                    if ~isempty(str)
                        transitions{i}.(f) = str;
                    end
                end
            end
        end
    end
end
