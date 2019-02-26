function [leftBound, topBound, rightBound, botBound] = sideExtremes(layout, portlessInfo, ignorePortlessBlocks)
% SIDEEXTREMES Find the extreme positions (left, top, right, and bottom)
%   among blocks in layout and portlessInfo (unless portless blocks
%   shouldn't be considered).
%
%   Inputs:
%       layout                  As returned by getRelativeLayout.
%       portlessInfo            As returned by getPortlessInfo.
%       ignorePortlessBlocks    Whether to consider portlessInfo (1) or not (0).
%
%   Outputs:
%       leftBound               Left bound of blocks of interest.
%       topBound                Top bound of blocks of interest.
%       rightBound              Right bound of blocks of interest.
%       botBound                Bottom bound of blocks of interest.

    % Extreme default values for the bounds
    rightBound = -32767;
    leftBound = 32767;
    botBound = -32767;
    topBound = 32767;

    %TODO: Optimize this to only check needed blocks

    % Go through each block and determine the current max bounds, ignoring portless
    % blocks
    for j = 1:size(layout.grid,2)
        for i = 1:layout.colLengths(j)
            pos = layout.grid{i,j}.position;
            if pos(3) > rightBound
                rightBound = pos(3);
            end
            if pos(1) < leftBound
                leftBound = pos(1);
            end

            if pos(4) > botBound
                botBound = pos(4);
            end
            if pos(2) < topBound
                topBound = pos(2);
            end
        end
    end

    % Determine the max bounds without ignoring portless blocks if the option is
    % selected
    if ~ignorePortlessBlocks
        for i = 1:length(portlessInfo)
            pos = portlessInfo{i}.position;
            if pos(3) > rightBound
                rightBound = pos(3);
            end
            if pos(1) < leftBound
                leftBound = pos(1);
            end

            if pos(4) > botBound
                botBound = pos(4);
            end
            if pos(2) < topBound
                topBound = pos(2);
            end
        end
    end
end