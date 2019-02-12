
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
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
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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
        StateflowTransition_To_Lustre.transitions_code(T, data_map, ...
        isDefaultTrans, parentPath, {}, {}, {}, {}, {});

    if isempty(outputs)
        return;
    end

    % creat node
    transitionNode = LustreNode();
    transitionNode.setName(node_name);
    transitionNode.setMetaInfo(comment);
    transitionNode.setBodyEqs(body);
    outputs = LustreVar.uniqueVars(outputs);
    inputs = LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            LustreVar(SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = LustreVar.removeVar(inputs, SF2LusUtils.virtualVarStr());
    end
    variables = LustreVar.uniqueVars(variables);
    transitionNode.setOutputs(outputs);
    transitionNode.setInputs(inputs);
    transitionNode.setLocalVars(variables);
    SF_STATES_NODESAST_MAP(node_name) = transitionNode;
end
