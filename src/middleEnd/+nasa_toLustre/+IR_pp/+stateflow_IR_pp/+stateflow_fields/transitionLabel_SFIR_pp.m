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
function [ new_ir, status ] = transitionLabel_SFIR_pp( new_ir )
    %transitionLabel_SFIR_pp use TransitionLabelParser.m instead of
    %edu.uiowa.chart.transition.TransitionParser.parse as it turns out it fails
    %in our unitTests.

    
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
