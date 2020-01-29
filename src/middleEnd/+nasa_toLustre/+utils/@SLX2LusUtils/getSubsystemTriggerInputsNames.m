
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [inputs] = getSubsystemTriggerInputsNames(parent, blk)
    [inputs] = nasa_toLustre.utils.SLX2LusUtils.getSpecialInputsNames(parent, blk, 'trigger');
end
