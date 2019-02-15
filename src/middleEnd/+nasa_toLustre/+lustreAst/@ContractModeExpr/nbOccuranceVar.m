function nb_occ = nbOccuranceVar(obj, var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    occ_requires = cellfun(@(x) x.nbOccuranceVar(var), obj.requires, ...
        'UniformOutput', true);
    occ_ensures = cellfun(@(x) x.nbOccuranceVar(var), obj.ensures, ...
        'UniformOutput', true);
    nb_occ = sum(occ_requires) + sum(occ_ensures);
end
