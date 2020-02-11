
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
%exit actions
function [body, outputs, inputs] = ...
        full_tran_exit_actions(transitions, parentPath, trans_cond)
    
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;

    body = {};
    outputs = {};
    inputs = {};
    %Add Exit Actions
    first_source = SF_STATES_PATH_MAP(transitions{1}.Source);
    last_destination = transitions{end}.Destination;
    source_parent = first_source;
    if ~strcmp(source_parent.Path, parentPath)
        %Go to the same level of the destination.
        while ~nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.isParent(...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(source_parent),...
                last_destination)
            source_parent = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(source_parent);
        end
        if strcmp(source_parent.Composition.Type,'AND')
            %Parallel state Exit.
            parent = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(source_parent);
            siblings = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getSubStatesObjects(parent), ...
                'ExecutionOrder');
            nbrsiblings = numel(siblings);
            for i=nbrsiblings:-1:1
                exitNodeName = ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getExitActionNodeName(siblings{i});
                if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                    %condition Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BoolExpr(false));
                    if isempty(trans_cond)
                        body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                            nasa_toLustre.lustreAst.IteExpr(trans_cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                end

            end
        else
            %Not Parallel state Exit
            exitNodeName = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getExitActionNodeName(source_parent);
            if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                %condition Action exists.
                actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BoolExpr(false));
                if isempty(trans_cond)
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                else
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                        nasa_toLustre.lustreAst.IteExpr(trans_cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                end
            end
        end
    else
        %the case of inner transition where we don't exit the parent state but we
        %exit active child
        exitNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getExitActionNodeName(source_parent);
        if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
            %condition Action exists.
            actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
            [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BoolExpr(true));
            if isempty(trans_cond)
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                    nasa_toLustre.lustreAst.IteExpr(trans_cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            end
        end
    end
    %remove isInner input from the node inputs
    inputs_name = cellfun(@(x) x.getId(), ...
        inputs, 'UniformOutput', false);
    inputs = inputs(~strcmp(inputs_name, ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.isInnerStr()));
end

