
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Entry actions
function [body, outputs, inputs, antiCondition] = ...
        full_tran_entry_actions(transitions, parentPath, trans_cond, isHJ)
    
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
    body = {};
    outputs = {};
    inputs = {};
    antiCondition = trans_cond;
    last_destination = transitions{end}.Destination;
    if isHJ
        dest_parent = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(...
            last_destination);
    else
        dest_parent = SF_STATES_PATH_MAP(last_destination.Name);
    end
    first_source = transitions{1}.Source;
    if ~strcmp(dest_parent.Path, parentPath)
        %Go to the same level of the destination.
        while ~nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.isParent(...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(dest_parent),...
                first_source)
            child = dest_parent;
            dest_parent = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(dest_parent);

            % set the child as active, so when the parent execute
            % entry action, it will enter the right child.
            if isHJ
                continue;
            end
            idParentName = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDName(...
                dest_parent);
            [idParentEnumType, idParentStateEnum] = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(dest_parent, child);
            body{end + 1} = nasa_toLustre.lustreAst.LustreComment(...
                sprintf('set state %s as active', child.Name));
            if isempty(trans_cond)
                body{end + 1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idParentName), ...
                    idParentStateEnum);
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idParentName, idParentEnumType);
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idParentName), ...
                    nasa_toLustre.lustreAst.IteExpr(trans_cond, idParentStateEnum, ...
                    nasa_toLustre.lustreAst.VarIdExpr(idParentName)));
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idParentName, idParentEnumType);
                inputs{end+1} = nasa_toLustre.lustreAst.LustreVar(idParentName, idParentEnumType);
            end

        end
        if strcmp(dest_parent.Composition.Type,'AND')
            %Parallel state Enter.
            parent = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getParent(dest_parent);
            siblings = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getSubStatesObjects(parent), ...
                'ExecutionOrder');
            nbrsiblings = numel(siblings);
            for i=1:nbrsiblings
                %if nbrsiblings{i}.Id == dest_parent.Id
                    %our parallel state we are entering
                %end
                entryNodeName = ...
                    nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(siblings{i});
                if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
                    %entry Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BooleanExpr(false));
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
            %Not Parallel state Entry
            entryNodeName = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(dest_parent);
            if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
                actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
                [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BooleanExpr(false));
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
        % this is a case of inner transition where the destination is
        %the parent state. We should not execute entry state of the parent

        if ~isHJ
            idState = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDName(...
                dest_parent);
            [idStateEnumType, idStateInactiveEnum] = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(dest_parent, [], ...
                false, false, true);
            body{end + 1} = nasa_toLustre.lustreAst.LustreComment(...
                sprintf('set state %s as inactive', dest_parent.Name));
            if isempty(trans_cond)
                body{end + 1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idState), ...
                    idStateInactiveEnum);
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idState, idStateEnumType);
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idState), ...
                    nasa_toLustre.lustreAst.IteExpr(trans_cond, idStateInactiveEnum, ...
                    nasa_toLustre.lustreAst.VarIdExpr(idState)));
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idState, idStateEnumType);
                inputs{end+1} = nasa_toLustre.lustreAst.LustreVar(idState, idStateEnumType);
            end
        end
        entryNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(dest_parent);
        if isKey(SF_STATES_NODESAST_MAP, entryNodeName)
            actionNodeAst = SF_STATES_NODESAST_MAP(entryNodeName);
            [call, oututs_Ids] = actionNodeAst.nodeCall(true, nasa_toLustre.lustreAst.BooleanExpr(true));
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
