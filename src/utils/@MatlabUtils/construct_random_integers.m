%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function vector = construct_random_integers(nb_iterations, IMIN, IMAX, dt, dim)
    if numel(dim)==1
        vector = randi([IMIN, IMAX], [nb_iterations,dim],dt);
    else
        vector = randi([IMIN, IMAX], [dim,nb_iterations],dt);
    end
end
