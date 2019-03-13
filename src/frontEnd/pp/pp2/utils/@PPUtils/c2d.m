function [Phi, Gamma] = c2d(a, b ,t)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    try
        % if c2d toolbox exist
        [Phi, Gamma] = c2d(a, b ,t);
    catch
        [m,n] = size(a); %#ok<ASGLU>
        [m,nb] = size(b); %#ok<ASGLU>
        s = expm([[a b]*t; zeros(nb,n+nb)]);
        Phi = s(1:n,1:n);
        Gamma = s(1:n,n+1:n+nb);
    end

end

