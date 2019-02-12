%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% state body
function [outputs, inputs, body, variables] = write_state_body(state)
    global SF_STATES_NODESAST_MAP ;%SF_STATES_PATH_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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
    idStateVar = VarIdExpr(...
            SF2LusUtils.getStateIDName(state));
    [idStateEnumType, idStateInactiveEnum] = ...
            SF2LusUtils.addStateEnum(state, [], ...
            false, false, true);    
    if ~isChart
        %parent = SF_STATES_PATH_MAP(parentPath);   
        %1st step: OuterTransition code
        cond_prefix = {};
        outerTransNodeName = ...
            SF2LusUtils.getStateOuterTransNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, outerTransNodeName)
            nodeAst = SF_STATES_NODESAST_MAP(outerTransNodeName);
            [call, oututs_Ids] = nodeAst.nodeCall();
            body{end+1} = LustreEq(oututs_Ids, call);
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            cond_name = ...
                StateflowTransition_To_Lustre.getValidPathCondName();
            if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                outputs = LustreVar.removeVar(outputs, cond_name);
                variables{end+1} = LustreVar(cond_name, 'bool');
                cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                    VarIdExpr(cond_name));
            end
        end

        %2nd step: During actions


        during_act_node_name = ...
            SF2LusUtils.getDuringActionNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, during_act_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(during_act_node_name);

            [call, oututs_Ids] = nodeAst.nodeCall();
            if isempty(cond_prefix)
                body{end+1} = LustreEq(oututs_Ids, call);
            else
                body{end+1} = LustreEq(oututs_Ids, ...
                    IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                inputs = [inputs, nodeAst.getOutputs()];
            end
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
        end

        %3rd step: Inner transitions
        innerTransNodeName = ...
            SF2LusUtils.getStateInnerTransNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, innerTransNodeName)
            nodeAst = SF_STATES_NODESAST_MAP(innerTransNodeName);
            [call, oututs_Ids] = nodeAst.nodeCall();
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            cond_name = ...
                StateflowTransition_To_Lustre.getValidPathCondName();
            if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                outputs = LustreVar.removeVar(outputs, cond_name);
            end
            if isempty(cond_prefix)
                body{end+1} = LustreEq(oututs_Ids, call);
                if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                    variables{end+1} = LustreVar(cond_name, 'bool');
                    cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                        VarIdExpr(cond_name));
                end
            else
                if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                    new_cond_name = strcat(cond_name, '_INNER');
                    variables{end+1} = LustreVar(new_cond_name, 'bool');
                    lhs_oututs_Ids = ...
                        SF2LusUtils.changeVar(...
                        oututs_Ids, cond_name, new_cond_name);
                    rhs_oututs_Ids = ...
                        SF2LusUtils.changeVar(...
                        oututs_Ids, cond_name, 'false');
                    body{end+1} = LustreEq(lhs_oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(rhs_oututs_Ids)));
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = LustreVar.removeVar(inputs, cond_name);
                    %add Inner termination condition
                    cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                        BinaryExpr(BinaryExpr.OR, ...
                        VarIdExpr(cond_name), VarIdExpr(new_cond_name)));
                else
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                    inputs = [inputs, nodeAst.getOutputs()];
                end
            end
        end
    else

        entry_act_node_name = ...
            SF2LusUtils.getEntryActionNodeName(state);
        if isKey(SF_STATES_NODESAST_MAP, entry_act_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(entry_act_node_name);
            [call, oututs_Ids] = nodeAst.nodeCall(true, BooleanExpr(false));
            cond = BinaryExpr(BinaryExpr.EQ,...
                idStateVar, idStateInactiveEnum);
            children_actions{end+1} = LustreEq(oututs_Ids, ...
                IteExpr(cond, call, TupleExpr(oututs_Ids)));
            outputs = [outputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getOutputs()];
            inputs = [inputs, nodeAst.getInputs()];
            inputs{end + 1} = LustreVar(idStateVar, idStateEnumType);
            %remove isInner input from the node inputs
            inputs_name = cellfun(@(x) x.getId(), ...
                inputs, 'UniformOutput', false);
            inputs = inputs(~strcmp(inputs_name, ...
                SF2LusUtils.isInnerStr()));
        end
        cond_prefix = BinaryExpr(BinaryExpr.NEQ,...
            idStateVar, idStateInactiveEnum);
        %cond_prefix = {};
    end

    %4th step: execute the active child
    children = SF2LusUtils.getSubStatesObjects(state);
    number_children = numel(children);
    isParallel = isequal(state.Composition.Type, 'PARALLEL_AND');
    if number_children > 0 && ~isParallel
        inputs{end + 1} = LustreVar(idStateVar, idStateEnumType);
    end
    for i=1:number_children
        child = children{i};
        if isParallel
            cond = cond_prefix;
        else
            [~, childEnum] = ...
                SF2LusUtils.addStateEnum(state, child);
            cond = BinaryExpr(BinaryExpr.EQ, ...
                idStateVar, childEnum);
            if ~isempty(cond_prefix) && ~isChart
                cond = ...
                    BinaryExpr(BinaryExpr.AND, cond, cond_prefix);
            end
        end
        child_node_name = ...
            SF2LusUtils.getStateNodeName(child);
        if isKey(SF_STATES_NODESAST_MAP, child_node_name)
            nodeAst = SF_STATES_NODESAST_MAP(child_node_name);
            [call, oututs_Ids] = nodeAst.nodeCall();
            if isempty(cond)
                children_actions{end+1} = LustreEq(oututs_Ids, call);
                outputs = [outputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getInputs()];
            else
                children_actions{end+1} = LustreEq(oututs_Ids, ...
                    IteExpr(cond, call, TupleExpr(oututs_Ids)));
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
                body = MatlabUtils.concat(children_actions(2:end),...
                    children_actions(1));
            else
                body = [body, children_actions];
            end
        else
            body{end+1} = ConcurrentAssignments(children_actions);
        end
    end
end

