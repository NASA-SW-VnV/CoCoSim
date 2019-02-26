function sels = gcls
%% GCLS Get all currently selected lines.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels   Cell array of line handles.

    objs = find_system(gcs,'LookUnderMasks','on','Findall','on','FollowLinks', ...
        'on','Type','line','Selected','on');
    % Flip to put in correct order (top to bottom position in model)
    sels = flipud(objs);
end