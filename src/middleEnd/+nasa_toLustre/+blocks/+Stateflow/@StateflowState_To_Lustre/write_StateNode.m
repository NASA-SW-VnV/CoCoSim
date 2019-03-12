%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
%% State Node
function main_node  = write_StateNode(state)
    
    global SF_STATES_NODESAST_MAP;
    main_node = {};

    [outputs, inputs, body, variables] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_state_body(state);
    if isempty(body)
        %no code is required
        return;
    end
    %create the node
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateNodeName(state);
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(node_name);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Main node of state %s',...
        state.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    main_node.setLocalVars(variables);
    SF_STATES_NODESAST_MAP(node_name) = main_node;
end
