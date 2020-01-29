
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [inputs] = getSubsystemEnableInputsNames(parent, blk)
    [inputs] = nasa_toLustre.utils.SLX2LusUtils.getSpecialInputsNames(parent, blk, 'enable');
end
