%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function res = contains(str, pattern)
    try
        %use Matlab startsWith for Matlab versions > 2016
        res = contains(s, pattern);
    catch
        try
            % do not change it
            res = ~isempty(strfind(str, pattern));
        catch E
            throw(E);
        end
    end
end
