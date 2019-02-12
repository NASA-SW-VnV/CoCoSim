
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function node_name = getCondActionName(T)
    import nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre
    src = T.Source;
    if isempty(src)
        isDefaultTrans = true;
    else
        isDefaultTrans = false;
    end
    transition_prefix = ...
        StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
    node_name = sprintf('%s_Cond', transition_prefix);
end
