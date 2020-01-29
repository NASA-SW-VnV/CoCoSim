
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function name = getStateOuterTransNodeName(state)
    
    state_name = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state);
    name = strcat(state_name, '_OuterTrans_Node');
end
