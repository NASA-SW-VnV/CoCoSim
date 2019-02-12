
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idName = getStateIDName(state)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    state_name = lower(...
        SF2LusUtils.getUniqueName(state));
    idName = strcat(state_name, ...
        SF2LusUtils.getStateIDSuffix());
end
