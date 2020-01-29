function nb_occ = nbOccuranceVar(obj, var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.assignments, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq);
end
