function obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    obj.inputs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.inputs, 'UniformOutput', 0);
    obj.outputs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.outputs, 'UniformOutput', 0);
   
end
