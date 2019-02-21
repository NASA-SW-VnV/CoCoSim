
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get_DefaultTransitionsNode
function [transitionNode, external_libraries] = ...
        get_DefaultTransitionsNode(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    parentPath = state.Path;
    T = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        state.Composition.DefaultTransitions, 'ExecutionOrder');
    isDefaultTrans = true;
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateDefaultTransNodeName(state);
    comment = LustreComment(...
        sprintf('Default transitions of state %s', state.Origin_path), true);
    [transitionNode, external_libraries] = ...
        StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment);
end

