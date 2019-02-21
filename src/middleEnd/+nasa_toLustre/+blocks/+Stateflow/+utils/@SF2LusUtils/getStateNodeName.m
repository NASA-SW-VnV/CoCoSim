
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function name = getStateNodeName(state, id)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if nargin == 2
        state_name = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state, id);
    else
        state_name = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state);
    end
    name = strcat(state_name, '_Node');
end
