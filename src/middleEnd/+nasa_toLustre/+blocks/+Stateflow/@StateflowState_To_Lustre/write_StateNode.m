%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
%% State Node
function main_node  = write_StateNode(state)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP;
    main_node = {};

    [outputs, inputs, body, variables] = ...
        StateflowState_To_Lustre.write_state_body(state);
    if isempty(body)
        %no code is required
        return;
    end
    %create the node
    node_name = ...
        SF2LusUtils.getStateNodeName(state);
    main_node = LustreNode();
    main_node.setName(node_name);
    comment = LustreComment(...
        sprintf('Main node of state %s',...
        state.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = LustreVar.uniqueVars(outputs);
    inputs = LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    main_node.setLocalVars(variables);
    SF_STATES_NODESAST_MAP(node_name) = main_node;
end
