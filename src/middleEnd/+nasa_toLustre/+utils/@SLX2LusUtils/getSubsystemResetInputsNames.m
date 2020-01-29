
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [inputs] = getSubsystemResetInputsNames(parent, blk)
    [inputs] = nasa_toLustre.utils.SLX2LusUtils.getSpecialInputsNames(parent, blk, 'Reset');
end
