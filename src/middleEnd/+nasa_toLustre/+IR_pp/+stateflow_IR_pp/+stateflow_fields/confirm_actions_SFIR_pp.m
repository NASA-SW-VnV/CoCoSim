%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.  All
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS,
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
%
% Notice: The accuracy and quality of the results of running CoCoSim
% directly corresponds to the quality and accuracy of the model and the
% requirements given as inputs to CoCoSim. If the models and requirements
% are incorrectly captured or incorrectly input into CoCoSim, the results
% cannot be relied upon to generate or error check software being developed.
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_ir, status ] = confirm_actions_SFIR_pp( new_ir )
    %confirm_actions_SFIR_pp asks the user to confirm if we parsed actions
    %correctly, if not we update them by the user input.
    
    
    global CHECK_SF_ACTIONS;
    status = 0;
    if ~isempty(CHECK_SF_ACTIONS) && CHECK_SF_ACTIONS == 0
        display_msg(...
            sprintf(['Skip flag of Stateflow parser check was detected. Skipping parser check.\n', ...
            'To enable it go to: ']),...
            MsgType.INFO, 'confirm_actions_SFIR_pp', '');
        display_msg('tools -> CoCoSim -> Preferences -> NASA Compiler Preferences -> Skip Stateflow parser check. ', ...
            MsgType.RESULT, 'confirm_actions_SFIR_pp', '');
        return;
    else
        display_msg(...
            sprintf('To Disable parsing checks of Stateflow State/transition actions, go to: '),...
            MsgType.INFO, 'confirm_actions_SFIR_pp', '');
        display_msg('tools -> CoCoSim -> Preferences -> NASA Compiler Preferences -> Skip Stateflow parser check. ', ...
            MsgType.RESULT, 'confirm_actions_SFIR_pp', '');
    end
    
    if isfield(new_ir, 'States')
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
    end
    if isfield(new_ir, 'Junctions')
        for i=1:numel(new_ir.Junctions)
            junctionPath = new_ir.Junctions{i}.Path;
            new_ir.Junctions{i}.OuterTransitions = ...
                adapt_transitions(new_ir.Junctions{i}.OuterTransitions, junctionPath, 'Default');
        end
    end
    %
    if isfield(new_ir, 'GraphicalFunctions')
        for i=1:numel(new_ir.GraphicalFunctions)
            new_ir.GraphicalFunctions{i} = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.confirm_actions_SFIR_pp( new_ir.GraphicalFunctions{i} );
        end
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
                && ( MatlabUtils.contains(states{i}.LabelString, ':') ...
                || MatlabUtils.contains(states{i}.LabelString, ';')  ...%the case of one action without (en:|entry:) prefix
                || MatlabUtils.contains(states{i}.LabelString, '='))
            display_msg(...
                sprintf('We need your confirmation on state actions of the State\n %s:', ...
                statePath),...
                MsgType.INFO, 'confirm_actions', '');
            display_msg(...
                sprintf('The original StateLabel is :'),...
                MsgType.INFO, 'confirm_actions', '');
            
            cprintf('blue', states{i}.LabelString);
            fprintf('\n');
            for j=1:numel(states_fields)
                f = states_fields{j};
                if isfield(states{i}.Actions, f) ...
                        && MatlabUtils.contains(states{i}.LabelString, states_keywords{j})
                    if isempty(states{i}.Actions.(f))
                        action = 'not defined';
                    else
                        action = states{i}.Actions.(f);
                        if iscell(action)
                            action = MatlabUtils.strjoin(action, '\n');
                        end
                    end
                    display_msg(...
                        sprintf('We assumed "%s" action is :',f),...
                        MsgType.INFO, 'confirm_actions', '');
                    cprintf('blue', action);
                    fprintf('\n');
                end
            end
            prompt = 'Are all the above actions correct? Y/N [Y]: ';
            str = input(prompt,'s');
            if ~isempty(str) && strcmp(upper(str), 'N')
                for j=1:numel(states_fields)
                    f = states_fields{j};
                    if isfield(states{i}.Actions, f) ...
                            && MatlabUtils.contains(states{i}.LabelString, states_keywords{j})
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
                && ~strcmp(transitions{i}.LabelString, '?')
            display_msg(...
                sprintf('We need your confirmation on %s transition number %d of the State\n %s:', ...
                transitionType, transitions{i}.ExecutionOrder, statePath),...
                MsgType.INFO, 'confirm_actions', '');
            display_msg(...
                sprintf('The original Transition label is :'),...
                MsgType.INFO, 'confirm_actions', '');
            cprintf('blue', transitions{i}.LabelString);
            fprintf('\n');
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
                        sprintf('We assumed "%s" of the transition is :',f),...
                        MsgType.INFO, 'confirm_actions', '');
                    cprintf('blue', action);
                    fprintf('\n');
                end
            end
            prompt = 'Are all the above parts correct? Y/N [Y]: ';
            str = input(prompt,'s');
            if ~isempty(str) && strcmp(upper(str), 'N')
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
