function obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    obj.requires = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.requires, ...
        'UniformOutput', 0);
    obj.ensures = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.ensures, ...
        'UniformOutput', 0);
end
