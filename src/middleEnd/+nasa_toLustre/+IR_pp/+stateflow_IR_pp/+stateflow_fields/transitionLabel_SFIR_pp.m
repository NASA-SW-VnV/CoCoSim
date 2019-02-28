function [ new_ir, status ] = transitionLabel_SFIR_pp( new_ir )
    %transitionLabel_SFIR_pp use TransitionLabelParser.m instead of
    %edu.uiowa.chart.transition.TransitionParser.parse as it turns out it fails
    %in our unitTests.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    import nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.transitionLabel_SFIR_pp
    status = false;
    if isfield(new_ir, 'States')
        for i=1:numel(new_ir.States)
            % default transition
            [new_ir.States{i}.Composition.DefaultTransitions, status_i] = ...
                adapt_transitions(new_ir.States{i}.Composition.DefaultTransitions);
            if status_i
                display_msg(['ERROR found in pre-processing state:' new_ir.States{i}.Path], ...
                    MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
            end
            status = status + status_i;
            
            %OuterTransitions
            [new_ir.States{i}.OuterTransitions, status_i] = ...
                adapt_transitions(new_ir.States{i}.OuterTransitions);
            if status_i
                display_msg(['ERROR found in pre-processing state:' new_ir.States{i}.Path], ...
                    MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
            
            %InnerTransitions
            [new_ir.States{i}.InnerTransitions, status_i] = ...
                adapt_transitions(new_ir.States{i}.InnerTransitions);
            if status_i
                display_msg(['ERROR found in pre-processing state:' new_ir.States{i}.Path], ...
                    MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
    if isfield(new_ir, 'Junctions')
        for i=1:numel(new_ir.Junctions)
            [new_ir.Junctions{i}.OuterTransitions, status_i] = ...
                adapt_transitions(new_ir.Junctions{i}.OuterTransitions);
            if status_i
                display_msg(['ERROR found in Junction:' new_ir.Junctions{i}.Path], ...
                    MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
    if isfield(new_ir, 'GraphicalFunctions')
        for i=1:numel(new_ir.GraphicalFunctions)
            [new_ir.GraphicalFunctions{i}, status_i] = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.transitionLabel_SFIR_pp( new_ir.GraphicalFunctions{i} );
            if status_i
                display_msg(['ERROR found in StateflowFunction:' new_ir.GraphicalFunctions{i}.origin_path], ...
                    MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
end

%%
function [transitions, status] = adapt_transitions(transitions)
    status = 0;
    for i=1:numel(transitions)
        [transitionObject, status_i, unsupportedExp] = ...
            nasa_toLustre.utils.TransitionLabelParser(transitions{i}.LabelString);
        if status_i
            display_msg(sprintf('ParseError  character unsupported  %s \n in LabelString %s', ...
                unsupportedExp, transitions{i}.LabelString), ...
                MsgType.ERROR, 'transitionLabel_SFIR_pp', '');
            continue;
        end
        transitions{i}.Event = transitionObject.eventOrMessage;
        transitions{i}.Condition = transitionObject.condition;
        transitions{i}.ConditionAction = transitionObject.conditionAction;
        transitions{i}.TransitionAction = transitionObject.transitionAction;
        
        status = status + status_i;
    end
end
