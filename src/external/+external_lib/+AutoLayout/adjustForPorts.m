function layout = adjustForPorts(layout)
% ADJUSTFORTEXT Adjust layout top/bottom positions to resize blocks to accomodate
%   their ports without disturbing the relative layout.
%
%   Inputs:
%       layout      As returned by getRelativeLayout.
%
%   Outputs:
%       layout      With modified position information.

    for j = 1:size(layout.grid,2) % for each column
        for i = 1:layout.colLengths(j) % for each non empty row in column
            block = layout.grid{i,j}.fullname; % block to resize
            pos = layout.grid{i,j}.position;
            [layout.grid{i,j}.position, yDisplace] = dimIncreaseForPorts(...
                block, pos, 'bot'); % Returns amount to move other blocks

            layout = vertMoveColumn(layout, i, j, yDisplace);
        end
    end
end