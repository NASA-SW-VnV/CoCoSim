
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% reset conditions
function isSupported = resetTypeIsSupported(resetType)
    supported = {'rising', 'falling', 'either', 'level', 'level hold', 'function-call'};
    isSupported = ismember(lower(resetType), supported);
end
