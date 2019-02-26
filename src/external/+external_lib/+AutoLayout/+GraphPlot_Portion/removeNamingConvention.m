function name = removeNamingConvention(handle)
% REMOVENAMINGCONVENTION Remove a naming convention from blocks and ports.
%   May be expanded to other elements in the future.
%
%   Inputs:
%       handle  Handle of the block/port. Block name is also accepted.
%
%   Outputs:
%       name    Name with convention removed from it.

    % Check handle argument
    try
        assert(~isempty(handle));
    catch
        error('Invalid handle.');
    end

    name = getfullname(handle);
end