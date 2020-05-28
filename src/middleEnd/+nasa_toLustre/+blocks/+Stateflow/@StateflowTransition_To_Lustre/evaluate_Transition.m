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
function [body, outputs, inputs, variables, external_libraries, ...
        validDestination_cond, Termination_cond, hasJunctionLoop] = ...
        evaluate_Transition(t, data_map, isDefaultTrans, ...
        isFlowChartJunction, parentPath, ...
        validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
    
    global SF_STATES_NODESAST_MAP SF_JUNCTIONS_PATH_MAP;
    body = {};
    outputs = {};
    inputs = {};
    external_libraries = {};
    hasJunctionLoop = false;
    % Transition is marked for evaluation.
    % Does the transition have a condition?
    [trans_cond, outputs_i, inputs_i, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(t.Condition, data_map, true, parentPath);
    if iscell(trans_cond)
        if numel(trans_cond) == 1
            trans_cond = trans_cond{1};
        elseif numel(trans_cond) > 1
            trans_cond = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                trans_cond);
        end
    end
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    [event, outputs_i, inputs_i, ~] = ...
        nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(t.Event,data_map, true, parentPath);
    if iscell(event)
        if numel(event) == 1
            event = event{1};
        elseif numel(event) > 1
            event = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                event);
        end
    end
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    if ~isempty(trans_cond) && ~isempty(event)
        trans_cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, trans_cond, event);
    elseif ~isempty(event)
        trans_cond = event;
    end
    % add cond_prefix
    if ~isempty(cond_prefix)
        if ~isempty(trans_cond)
            trans_cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, cond_prefix, trans_cond);
        else
            trans_cond = cond_prefix;
        end
    end
    % add condition variable so the condition action can not change
    % the truth value of the condition.
    if ~isempty(trans_cond) && ~isa(trans_cond, 'nasa_toLustre.lustreAst.VarIdExpr')
        condName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getCondActNewVarName(t);
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(condName), trans_cond);
        trans_cond = nasa_toLustre.lustreAst.VarIdExpr(condName);
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(condName, 'bool');
    end
    
    % add no valid transition path was found
    if ~isempty(Termination_cond)
        if ~isempty(trans_cond)
            trans_cond_with_termination = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, Termination_cond), trans_cond);
        else
            trans_cond_with_termination = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, Termination_cond);
        end
    else
        trans_cond_with_termination = trans_cond;
    end
    
    
    
    %execute condition action
    
    transCondActionNodeName = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getCondActionNodeName(t);
    if isKey(SF_STATES_NODESAST_MAP, transCondActionNodeName)
        %condition Action exists.
        actionNodeAst = SF_STATES_NODESAST_MAP(transCondActionNodeName);
        [call, oututs_Ids] = actionNodeAst.nodeCall();
        if isempty(trans_cond_with_termination)
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
            outputs = [outputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getInputs()];
        else
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                nasa_toLustre.lustreAst.IteExpr(trans_cond_with_termination, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
            outputs = [outputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getInputs()];
        end
    end
    
    
    %Is the destination a state or a junction?
    destination = t.Destination;
    isHJ = false;
    if strcmp(destination.Type,'Junction')
        %the destination is a junction
        if ~isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
            display_msg(...
                sprintf('%s not found in SF_JUNCTIONS_PATH_MAP',...
                destination.Name), ...
                MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
            return;
        end
        
        hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
        if strcmp(hobject.Type, 'HISTORY')
            isHJ = true;
        else
            %Does the junction have any outgoing transitions?
            transitions2 = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                hobject.OuterTransitions, 'ExecutionOrder');
            if isempty(transitions2)
                %the junction has no outgoing transitions
                %update termination condition
                termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTerminationCondName();
                [Termination_cond, body, outputs] = ...
                    nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.updateTerminationCond(...
                    Termination_cond, termVarName, trans_cond, body, outputs, isFlowChartJunction);
            else
                %the junction has outgoing transitions
                %Repeat the algorithm
                
                % check if this junction is part of a flow chart (no
                % state final destination).
                junctionOuterTransName = ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateOuterTransNodeName(hobject);
                if isKey(SF_STATES_NODESAST_MAP, junctionOuterTransName)
                    %Flowchart Junciton outerTransitions node exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(junctionOuterTransName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall();
                    if isempty(trans_cond_with_termination)
                        body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                            nasa_toLustre.lustreAst.IteExpr(trans_cond_with_termination, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                    termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTerminationCondName();
                    Termination_cond = nasa_toLustre.lustreAst.VarIdExpr(termVarName);
                else
                    [body_i, outputs_i, inputs_i, variables, ...
                        external_libraries_i, ...
                        validDestination_cond, Termination_cond_i, hasJunctionLoop] = ...
                        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.transitions_code(...
                        transitions2, data_map, isDefaultTrans, ...
                        isFlowChartJunction, ...
                        parentPath, ...
                        validDestination_cond, Termination_cond, ...
                        trans_cond, fullPathT, variables);
                    
                    body = [body, body_i];
                    outputs = [outputs, outputs_i];
                    inputs = [inputs, inputs_i];
                    external_libraries = [external_libraries, external_libraries_i];
                    
                    if ~hasJunctionLoop && ...
                            ~isempty(Termination_cond_i) && ...
                            has_clear_path_to_final_destination(transitions2)
                        % To optimize the termination condition. If the
                        % branch has clear path to final destination with
                        % no conditions, then the termination condition is
                        % the current trans_cond.
                        %update termination condition
                        %Termination_cond = trans_cond;
                        termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTerminationCondName();
                        [Termination_cond, body, outputs] = ...
                            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.updateTerminationCond(...
                            Termination_cond, termVarName, trans_cond, body, outputs, false);
                    else
                        Termination_cond = Termination_cond_i;
                    end
                end
            end
            return;
        end
        
    end
    %the destination is a state or History Junction
    % Exit action should be executed.
    if ~isDefaultTrans && ~isFlowChartJunction
        [body_i, outputs_i, inputs_i] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.full_tran_exit_actions(...
            fullPathT, parentPath, trans_cond_with_termination);
        body = [body, body_i];
        outputs = [outputs, outputs_i];
        inputs = [inputs, inputs_i];
    end
    % Transition actions
    [body_i, outputs_i, inputs_i] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.full_tran_trans_actions(...
        fullPathT, trans_cond_with_termination);
    body = [body, body_i];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    
    % Entry actions
    [body_i, outputs_i, inputs_i] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.full_tran_entry_actions(...
        fullPathT, parentPath, trans_cond_with_termination, isHJ);
    body = [body, body_i];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    
    %update termination condition
    termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTerminationCondName();
    [Termination_cond, body, outputs] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.updateTerminationCond(...
        Termination_cond, termVarName, trans_cond, body, outputs, false);
    
    %validDestination_cond only updated if the final destination is a state
    if ~isDefaultTrans && ~isFlowChartJunction
        termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getValidPathCondName();
        [validDestination_cond, body, outputs] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.updateTerminationCond(...
            validDestination_cond, termVarName, trans_cond, body, outputs, true);
    end
end


function res = has_clear_path_to_final_destination(transitions)
    global SF_JUNCTIONS_PATH_MAP
    res = false;
    if isempty(transitions)
        res = true;
        return
    end
    n = length(transitions);
    for i = 1:n
        t = transitions{i};
        if isempty(t.Condition) && isempty(t.Event)
            destination = t.Destination;
            if strcmp(destination.Type,'Junction')
                %the destination is a junction
                if isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
                    hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
                    if strcmp(hobject.Type, 'HISTORY')
                        res = true;
                        return
                    else
                        %Does the junction have any outgoing transitions?
                        transitions2 = ...
                            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                            hobject.OuterTransitions, 'ExecutionOrder');
                        res = res || ...
                            has_clear_path_to_final_destination(transitions2);
                    end
                end
            else
                res = true;
                return
            end
        end
    end
end
