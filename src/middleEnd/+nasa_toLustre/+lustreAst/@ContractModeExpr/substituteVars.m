function obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    obj.requires = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.requires, ...
        'UniformOutput', 0);
    obj.ensures = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.ensures, ...
        'UniformOutput', 0);
end
