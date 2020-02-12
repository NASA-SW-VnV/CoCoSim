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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% state body
function [outputs, inputs, body, variables] = write_state_body(state)
    global SF_STATES_NODESAST_MAP ;%SF_STATES_PATH_MAP;
    
    outputs = {};
    inputs = {};
    variables = {};
    body = {};
    children_actions = {};
    parentPath = fileparts(state.Path);
    isChart = false;
    if isempty(parentPath)
        isChart = true;
    end
    idStateVar = nasa_toLustre.lustreAst.VarIdExpr(...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDName(state));
    [idStateEnumType, idStateInactiveEnum] = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(state, [], ...
            false, false, true);    
    if ~isChart
        %parent = SF_STATES_PATH_MAP(parentPath);   
        %1st step: OuterTransition code
        cond_prefix = {};
        outerTransNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateOuterTransNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, outerTransNodeName)
            nodeAst = SF_STATES_NODESAST_MAP(outerTransNodeName);
            [call, oututs_Ids] = nodeAst.nodeCall();
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            cond_name = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getValidPathCondName();
            if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                outputs = nasa_toLustre.lustreAst.LustreVar.removeVar(outputs, cond_name);
                variables{end+1} = nasa_toLustre.lustreAst.LustreVar(cond_name, 'bool');
                cond_prefix = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT,...
                    nasa_toLustre.lustreAst.VarIdExpr(cond_name));
            end
        end

        %2nd step: During actions


        during_act_node_name = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDuringActionNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, during_act_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(during_act_node_name);

            [call, oututs_Ids] = nodeAst.nodeCall();
            if isempty(cond_prefix)
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                    nasa_toLustre.lustreAst.IteExpr(cond_prefix, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                inputs = [inputs, nodeAst.getOutputs()];
            end
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
        end

        %3rd step: Inner transitions
        innerTransNodeName = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateInnerTransNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, innerTransNodeName)
            nodeAst = SF_STATES_NODESAST_MAP(innerTransNodeName);
            [call, oututs_Ids] = nodeAst.nodeCall();
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            cond_name = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getValidPathCondName();
            if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                outputs = nasa_toLustre.lustreAst.LustreVar.removeVar(outputs, cond_name);
            end
            if isempty(cond_prefix)
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(cond_name, 'bool');
                    cond_prefix = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT,...
                        nasa_toLustre.lustreAst.VarIdExpr(cond_name));
                end
            else
                if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                    new_cond_name = strcat(cond_name, '_INNER');
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(new_cond_name, 'bool');
                    lhs_oututs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        oututs_Ids, cond_name, new_cond_name);
                    rhs_oututs_Ids = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.changeVar(...
                        oututs_Ids, cond_name, 'false');
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(lhs_oututs_Ids, ...
                        nasa_toLustre.lustreAst.IteExpr(cond_prefix, call, nasa_toLustre.lustreAst.TupleExpr(rhs_oututs_Ids)));
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, cond_name);
                    %add Inner termination condition
                    cond_prefix = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT,...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, ...
                        nasa_toLustre.lustreAst.VarIdExpr(cond_name), nasa_toLustre.lustreAst.VarIdExpr(new_cond_name)));
                else
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                        nasa_toLustre.lustreAst.IteExpr(cond_prefix, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                    inputs = [inputs, nodeAst.getOutputs()];
                end
            end
        end
    else

        entry_act_node_name = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, entry_act_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(entry_act_node_name);
            [call, oututs_Ids] = nodeAst.nodeCall(true, nasa_toLustre.lustreAst.BoolExpr(false));
            cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                idStateVar, idStateInactiveEnum);
            children_actions{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                nasa_toLustre.lustreAst.IteExpr(cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idStateVar, idStateEnumType);
            %remove isInner input from the node inputs
            inputs_name = cellfun(@(x) x.getId(), ...
                inputs, 'UniformOutput', false);
            inputs = inputs(~strcmp(inputs_name, ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.isInnerStr()));
        end
        cond_prefix = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ,...
            idStateVar, idStateInactiveEnum);
        %cond_prefix = {};
    end

    %4th step: execute the active child
    children = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getSubStatesObjects(state);
    number_children = numel(children);
    isParallel = strcmp(state.Composition.Type, 'PARALLEL_AND');
    if number_children > 0 && ~isParallel
        inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(idStateVar, idStateEnumType);
    end
    for i=1:number_children
        child = children{i};
        if isParallel
            cond = cond_prefix;
        else
            [~, childEnum] = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(state, child);
            cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                idStateVar, childEnum);
            if ~isempty(cond_prefix) && ~isChart
                cond = ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, cond, cond_prefix);
            end
        end
        child_node_name = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateNodeName(child);
        if isKey(SF_STATES_NODESAST_MAP, child_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(child_node_name);
            [call, oututs_Ids] = nodeAst.nodeCall();
            if isempty(cond)
                children_actions{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                outputs = [outputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getInputs()];
            else
                children_actions{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                    nasa_toLustre.lustreAst.IteExpr(cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                outputs = [outputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getInputs()];
            end
        end
    end
    if ~isempty(children_actions)
        if isParallel
            if isChart
                % entry action condition is concurrent with
                % substates nodes call.
                body = coco_nasa_utils.MatlabUtils.concat(children_actions(2:end),...
                    children_actions(1));
            else
                body = [body, children_actions];
            end
        else
            body{end+1} = nasa_toLustre.lustreAst.ConcurrentAssignments(children_actions);
        end
    end
end

