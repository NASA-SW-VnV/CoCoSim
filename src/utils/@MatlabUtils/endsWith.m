%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function tf = endsWith(s, pattern)
    try
        %use Matlab startsWith for Matlab versions > 2015
        tf = endsWith(s, pattern);
    catch
        try
            res = regexp(s, strcat(pattern, '$'), 'match', 'once');
            if ischar(res)
                res = {res};
            end
            tf = cellfun(@(x) ~isempty(x), res);
        catch E
            throw(E);
        end
    end
end
