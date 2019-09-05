%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function res = contains(str, pattern)
    try
        %use Matlab startsWith for Matlab versions > 2016
        res = contains(str, pattern);
    catch
        try
            % do not change it
            if iscell(str)
                res = cellfun(@(x) ~isempty(strfind(x, pattern)), str);
            else
                res = ~isempty(strfind(str, pattern));
            end
        catch E
            throw(E);
        end
    end
end
