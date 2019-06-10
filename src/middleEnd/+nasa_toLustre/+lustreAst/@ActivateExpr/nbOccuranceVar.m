function nb_occ = nbOccuranceVar(obj, var)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.nodeArgs, 'UniformOutput', true);
    nb_occ = sum(nb_occ_perEq) + obj.activate_cond.nbOccuranceVar(var);
    if obj.has_restart
        nb_occ = nb_occ + obj.has_restart.nbOccuranceVar(var);
    end
end
