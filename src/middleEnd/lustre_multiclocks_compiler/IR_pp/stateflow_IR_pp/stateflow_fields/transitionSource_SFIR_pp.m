function [ new_ir, status ] = transitionSource_SFIR_pp( new_ir )
    %transitionSource_SFIR_pp add Source field
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = false;
    for i=1:numel(new_ir.States)
        src = new_ir.States{i};
        % default transition
        [new_ir.States{i}.Composition.DefaultTransitions, status_i] = ...
            adapt_transitions(src.Composition.DefaultTransitions, []);
        if status_i
            display_msg(['ERROR found in pre-processing state:' src.Path], ...
                MsgType.ERROR, 'transitionSource_SFIR_pp', '');
        end
        status = status + status_i;
        
        %OuterTransitions
        [new_ir.States{i}.OuterTransitions, status_i] = ...
            adapt_transitions(src.OuterTransitions, src);
        if status_i
            display_msg(['ERROR found in pre-processing state:' src.Path], ...
                MsgType.ERROR, 'transitionSource_SFIR_pp', '');
            %return;
        end
        status = status + status_i;
        
        %InnerTransitions
        [new_ir.States{i}.InnerTransitions, status_i] = ...
            adapt_transitions(src.InnerTransitions, src);
        if status_i
            display_msg(['ERROR found in pre-processing state:' src.Path], ...
                MsgType.ERROR, 'transitionSource_SFIR_pp', '');
            %return;
        end
        status = status + status_i;
    end
    
    
    for i=1:numel(new_ir.Junctions)
        jun = new_ir.Junctions{i};
        [new_ir.Junctions{i}.OuterTransitions, status_i] = ...
            adapt_transitions(jun.OuterTransitions, jun);
        if status_i
            display_msg(['ERROR found in Junction:' jun.Path], ...
                MsgType.ERROR, 'transitionSource_SFIR_pp', '');
            %return;
        end
        status = status + status_i;
    end
    
    for i=1:numel(new_ir.GraphicalFunctions)
        [new_ir.GraphicalFunctions{i}, status_i] = transitionSource_SFIR_pp( new_ir.GraphicalFunctions{i} );
        if status_i
            display_msg(['ERROR found in StateflowFunction:' new_ir.GraphicalFunctions{i}.origin_path], ...
                MsgType.ERROR, 'transitionSource_SFIR_pp', '');
            %return;
        end
        status = status + status_i;
    end
    
end

%%
function [transitions, status] = adapt_transitions(transitions, src)
    status = 0;
    for i=1:numel(transitions)
        transitions{i}.Source = src;
    end
end
