function [ new_ir, status ] = transitionSource_SFIR_pp( new_ir )
    %transitionSource_SFIR_pp add Source field
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    import nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.transitionSource_SFIR_pp
    status = false;
    if isfield(new_ir, 'States')
        for i=1:numel(new_ir.States)
            src = new_ir.States{i};
            % default transition
            [new_ir.States{i}.Composition.DefaultTransitions, status_i] = ...
                adapt_transitions(src.Composition.DefaultTransitions, '');
            if status_i
                display_msg(['ERROR found in pre-processing state:' src.Path], ...
                    MsgType.ERROR, 'transitionSource_SFIR_pp', '');
            end
            status = status + status_i;
            
            %OuterTransitions
            [new_ir.States{i}.OuterTransitions, status_i] = ...
                adapt_transitions(src.OuterTransitions, src.Path);
            if status_i
                display_msg(['ERROR found in pre-processing state:' src.Path], ...
                    MsgType.ERROR, 'transitionSource_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
            
            %InnerTransitions
            [new_ir.States{i}.InnerTransitions, status_i] = ...
                adapt_transitions(src.InnerTransitions, src.Path);
            if status_i
                display_msg(['ERROR found in pre-processing state:' src.Path], ...
                    MsgType.ERROR, 'transitionSource_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
    
    
    if isfield(new_ir, 'Junctions')
        for i=1:numel(new_ir.Junctions)
            jun = new_ir.Junctions{i};
            [new_ir.Junctions{i}.OuterTransitions, status_i] = ...
                adapt_transitions(jun.OuterTransitions, jun.Path);
            if status_i
                display_msg(['ERROR found in Junction:' jun.Path], ...
                    MsgType.ERROR, 'transitionSource_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
    
    
    if isfield(new_ir, 'GraphicalFunctions')
        for i=1:numel(new_ir.GraphicalFunctions)
            % default transition
            [new_ir.GraphicalFunctions{i}.Composition.DefaultTransitions, ~] = ...
                adapt_transitions(new_ir.GraphicalFunctions{i}.Composition.DefaultTransitions, '');
            % junctions
            [new_ir.GraphicalFunctions{i}, status_i] = transitionSource_SFIR_pp( new_ir.GraphicalFunctions{i} );
            if status_i
                display_msg(['ERROR found in StateflowFunction:' new_ir.GraphicalFunctions{i}.origin_path], ...
                    MsgType.ERROR, 'transitionSource_SFIR_pp', '');
                %return;
            end
            status = status + status_i;
        end
    end
end

%%
function [transitions, status] = adapt_transitions(transitions, srcPath)
    status = 0;
    for i=1:numel(transitions)
        transitions{i}.Source = srcPath;
    end
end
