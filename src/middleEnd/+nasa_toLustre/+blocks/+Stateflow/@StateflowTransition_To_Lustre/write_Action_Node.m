
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function  [main_node, external_nodes, external_libraries ] = ...
        write_Action_Node(action, data_map, t_act_node_name, transitionPath)
    
    global SF_STATES_NODESAST_MAP;
    main_node = {};
    external_nodes = {};
    external_libraries = {};
    actions = nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(action);
    if isempty(actions)
        return;
    end
    body = {};
    outputs = {};
    inputs = {};
    nb_actions = numel(actions);
    for i=1:nb_actions
        [actions_i, outputs_i, inputs_i, external_libraries_i] = ...
            nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(actions{i}, data_map, false, transitionPath);
        body = [body, actions_i];
        outputs = [outputs, outputs_i];
        inputs = [inputs, inputs_i];
        external_libraries = [external_libraries, external_libraries_i];
    end

    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(outputs)
        return;
    end
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(t_act_node_name);
    main_node.setBodyEqs(body);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(t_act_node_name) = main_node;

end


