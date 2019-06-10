
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idName = getStateIDName(state)
    
    state_name = lower(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state));
    idName = strcat(state_name, ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix());
end
