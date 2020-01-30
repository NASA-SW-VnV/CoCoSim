function nb_occ = nbOccuranceVar(obj, var)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.bodyEqs, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq);
end
