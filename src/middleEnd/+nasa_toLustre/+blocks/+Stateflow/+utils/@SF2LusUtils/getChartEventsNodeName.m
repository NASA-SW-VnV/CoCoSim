
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function name = getChartEventsNodeName(state, id)
    
    if nargin == 2
        state_name = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state, id);
    else
        state_name = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state);
    end
    name = strcat(state_name, '_EventsNode');
end

