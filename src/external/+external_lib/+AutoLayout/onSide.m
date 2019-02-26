function bool = onSide(block, center, side)
% ONSIDE Determine whether or not the center of block is on a particular side of
%   the system.
%
%   Inputs:
%       block   Full block name.
%       center  Center of the system for the given side (e.g. if side is
%               'left', center will be halfway between the largest and
%               smallest X positions of blocks in the system).
%       side    Either 'left' or 'top'. Indicates the side to compare
%               the given block's center with. E.g. If side is 'left', the
%               function checks if the center of the block is on the left
%               half of the system (if it's a tie then choose left)
%
%   Outputs:
%       bool    Whether or not the given block is on the indicated side of the system.

    switch side
        case 'left'
            midPos = getBlockSidePositions({block}, 5);
        case 'top'
            midPos = getBlockSidePositions({block}, 6);
    end
    bool = midPos <= center;
end