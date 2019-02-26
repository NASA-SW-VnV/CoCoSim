function [layout, portlessInfo] = resizeBlocks(layout, portlessInfo)
% RESIZEBLOCKS Determine desired end sizes for all blocks.
%
%   Inputs:
%       layout          As returned by getRelativeLayout.
%       portlessInfo    As returned by getPortlessInfo.
%
%   Outputs:
%       layout          With modified position information.
%       portlessInfo    With modified position information.

    % Resize horizontally to fit the strings within blocks
    layout = adjustForText(layout);

    % Horizontally resize portless blocks for text too
    for i = 1:length(portlessInfo)
        portlessInfo{i}.position(3) = max(portlessInfo{i}.position(3), ...
            portlessInfo{i}.position(1) + getBlockTextWidth(portlessInfo{i}.fullname));
    end

    % Resize vertically to comfortably fit ports
    layout = adjustForPorts(layout); % Result does not consider surrounding blocks, code is much cleaner
    % layout = resizeForPorts(layout); % Result considers surrounding blocks, code is less clean
end