
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get_OuterTransitionsNode
function [transitionNode, external_libraries] = ...
        get_OuterTransitionsNode(state, data_map)
    
    transitionNode = {};
    external_libraries = {};
    parentPath = fileparts(state.Path);
    if isempty(parentPath)
        %main chart
        return;
    end
    T = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        state.OuterTransitions, 'ExecutionOrder');
    isDefaultTrans = false;
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateOuterTransNodeName(state);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Outer transitions of state %s', state.Origin_path), true);
    [transitionNode, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment);
end
