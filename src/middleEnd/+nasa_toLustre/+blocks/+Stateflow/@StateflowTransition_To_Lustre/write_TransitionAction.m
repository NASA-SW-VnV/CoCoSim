
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  [main_node, external_nodes, external_libraries ] = ...
        write_TransitionAction(T, data_map, source_state, isDefaultTrans)
    
    [main_node, external_nodes, external_libraries ] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.write_Action(T, data_map, source_state, 'TransitionAction', isDefaultTrans);
end

