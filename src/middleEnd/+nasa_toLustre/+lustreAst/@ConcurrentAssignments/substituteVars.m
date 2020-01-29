function obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    obj.assignments = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.assignments, 'UniformOutput', 0);
end
