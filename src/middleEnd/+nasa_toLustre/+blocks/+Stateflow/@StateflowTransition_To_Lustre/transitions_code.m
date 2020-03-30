
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Transition code
function [body, outputs, inputs, variables, external_libraries, ...
        validDestination_cond, Termination_cond, hasJunctionLoop] = ...
        transitions_code(transitions, data_map, isDefaultTrans, parentPath, ...
        validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)

    body = {};
    outputs = {};
    inputs = {};
    external_libraries = {};
    hasJunctionLoop = false;
    n = length(transitions);
    fullPathIDs = cellfun(@(x) x.Id, fullPathT, 'un', true);
    for i=1:n
        % detect if there is closed loop in Junctions,
        % transitions(i) is in fullPathT
        if ismember(transitions{i}.Id, fullPathIDs)
            hasJunctionLoop = true;
            msg = sprintf('Transition from %s creates a closed loop of Junctions. Closed loop in Stateflow Control Flow is not supported.',...
                transitions{i}.Source);
            display_msg(msg, MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
            %return
            %             ME = MException('COCOSIM:SF:JUNCTIONS_LOOP', msg);
            %             throw(ME);
            % Ignore this transition that close the loop
            continue;
        end
        t_list = [fullPathT, transitions(i)];

        [body_i, outputs_i, inputs_i, variables, external_libraries_i, ...
            validDestination_cond, Termination_cond, hasJunctionLoop_i] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.evaluate_Transition(...
            transitions{i}, data_map, isDefaultTrans, parentPath, ...
            validDestination_cond, Termination_cond, ...
            cond_prefix, t_list, variables);
        hasJunctionLoop = hasJunctionLoop || hasJunctionLoop_i;
        body = [ body , body_i ];
        outputs = [ outputs , outputs_i ] ;
        inputs = [ inputs , inputs_i ] ;
        external_libraries = [external_libraries , external_libraries_i];
    end
end
