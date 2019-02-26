function [pos, xIncrease] = dimIncreaseForText(block, pos, varargin)
% DIMINCREASEFORTEXT Find the amount to increase the right and left positions
%   of the block in order to fit its text within it.
%
%   Inputs:
%       block       Full name of a block (character array).
%
%       pos         Current position of the block.
%                   In the form [left top right bottom].
%
%       varargin    Direction(s) to expand the block to fit its text:
%                   'left' - expand toward the left of the system.
%                   'equal' - expand toward the left and right sides of the
%                   system equally.
%                   Other strings or no input result in a default of
%                   expanding toward the right of the system.
%
%   Outputs:
%       pos         New position of the block.
%       xIncrease   Amount this block's width needs to be adjusted.

    xIncrease = getTextXIncrease(block, pos);

    % Increase xIncrease marginally for blocks needing resizing
    % Rationale: set_param(<block>,'Position',<position>) sometimes resizes
    % to a smaller size than indicated, this should ensure that blocks
    % needing to be widened will be widened sufficiently
    lbound = 0; % Lower bound
    if xIncrease > lbound
        buffer = 10;
        xIncrease = xIncrease + buffer;
    end

    if nargin > 2
        if strcmp(varargin{1}, 'left')
            % Increase block size toward the left
            pos(1) = pos(1) - xIncrease;
        elseif strcmp(varargin{1}, 'equal')
            % Increase block size left and right equally
            pos(1) = pos(1) - xIncrease/2;
            pos(3) = pos(3) + xIncrease/2;
        else % Default case
            % Increase block size toward the right
            pos(3) = pos(3) + xIncrease;
        end
    else % Default case
        % Increase block size toward the right
        pos(3) = pos(3) + xIncrease;
    end
end

function xIncrease = getTextXIncrease(block, pos)
% GETTEXTXINCREASE Find the amount to increase the width of block in order to
%   fit the text within it.
%
%   Inputs:
%       block       Full name of a block (character array).
%       pos         Current position coordinates of the block.
%
%   Outputs:
%       xIncrease   Amount to increase block width to fit its text.

    currentWidth = pos(3) - pos(1);
    neededWidth = getBlockTextWidth(block);
    xIncrease = max(0, neededWidth - currentWidth);
end