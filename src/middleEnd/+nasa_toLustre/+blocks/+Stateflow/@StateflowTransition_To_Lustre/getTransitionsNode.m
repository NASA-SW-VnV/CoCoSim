
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%getTransitionsNode
function [transitionNode, external_libraries] = ...
        getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment)
    global SF_STATES_NODESAST_MAP;
    
    transitionNode = {};
    external_libraries = {};
    if isempty(parentPath)
        %main chart
        return;
    end
    if isempty(T)
        return;
    end
    % create body
    [body, outputs, inputs, variables, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.transitions_code(T, data_map, ...
        isDefaultTrans, parentPath, {}, {}, {}, {}, {});

    if isempty(outputs)
        return;
    end

    % creat node
    transitionNode = nasa_toLustre.lustreAst.LustreNode();
    transitionNode.setName(node_name);
    transitionNode.setMetaInfo(comment);
    transitionNode.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    variables = nasa_toLustre.lustreAst.LustreVar.uniqueVars(variables);
    transitionNode.setOutputs(outputs);
    transitionNode.setInputs(inputs);
    transitionNode.setLocalVars(variables);
    SF_STATES_NODESAST_MAP(node_name) = transitionNode;
end
