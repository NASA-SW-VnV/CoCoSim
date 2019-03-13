function [x,y] = systemCenter(blocks)
% SYSTEMCENTER Find the center of the system (relative to the block positions).
%
%   Inputs:
%       blocks  List of blocks.
%
%   Outputs:
%       x       x coordinate of the center of the bounds of the blocks.
%       y       y coordinate of the center of the bounds of the blocks.


    % Default extreme values for the bounds
    largestX = -32767; % right bound
    smallestX = 32767; % left bound
    largestY = -32767; % top bound
    smallestY = 32767; % bottom bound

    % For each block, compare its position to the current smallest bound and
    % set it as the new smallest bounds if is smaller
    for i = 1:length(blocks)
        leftPos = external_lib.AutoLayout.getBlockSidePositions(blocks(i), 1);
        topPos = external_lib.AutoLayout.getBlockSidePositions(blocks(i), 2);
        rightPos = external_lib.AutoLayout.getBlockSidePositions(blocks(i), 3);
        botPos = external_lib.AutoLayout.getBlockSidePositions(blocks(i), 4);

        if topPos < smallestY
            smallestY = topPos;
        elseif botPos > largestY
            largestY = botPos;
        end

        if leftPos < smallestX
            smallestX = leftPos;
        elseif rightPos > largestX
            largestX = rightPos;
        end
    end

    y = (largestY + smallestY) / 2;
    x = (largestX + smallestX) / 2;
end
