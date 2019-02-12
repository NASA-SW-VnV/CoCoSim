
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function  [main_node, external_nodes, external_libraries ] = ...
        write_Action_Node(action, data_map, t_act_node_name, transitionPath)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP;
    main_node = {};
    external_nodes = {};
    external_libraries = {};
    actions = SFIRPPUtils.split_actions(action);
    if isempty(actions)
        return;
    end
    body = {};
    outputs = {};
    inputs = {};
    nb_actions = numel(actions);
    for i=1:nb_actions
        [actions_i, outputs_i, inputs_i, external_libraries_i] = ...
            getPseudoLusAction(actions{i}, data_map, false, transitionPath);
        body = [body, actions_i];
        outputs = [outputs, outputs_i];
        inputs = [inputs, inputs_i];
        external_libraries = [external_libraries, external_libraries_i];
    end

    outputs = LustreVar.uniqueVars(outputs);
    inputs = LustreVar.uniqueVars(inputs);
    if isempty(outputs)
        return;
    end
    main_node = LustreNode();
    main_node.setName(t_act_node_name);
    main_node.setBodyEqs(body);
    if isempty(inputs)
        inputs{1} = ...
            LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(t_act_node_name) = main_node;

end


