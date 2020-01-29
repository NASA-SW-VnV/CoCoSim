function obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    obj.inputs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.inputs, 'UniformOutput', 0);
    obj.outputs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.outputs, 'UniformOutput', 0);
   
end
