%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function vector = construct_random_doubles(nb_iterations, IMIN, IMAX,dim)
    if numel(dim)==1
        vector = double(IMIN + (IMAX-IMIN).*rand([nb_iterations,dim]));
    else
        vector = double(IMIN + (IMAX-IMIN).*rand([dim, nb_iterations]));
    end
end
