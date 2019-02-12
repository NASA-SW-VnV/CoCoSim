
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idName = getStateEnumType(state)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    state_name = lower(...
        SF_To_LustreNode.getUniqueName(state));
    idName = strcat(state_name, ...
        SF2LusUtils.getStateEnumSuffix());
end
