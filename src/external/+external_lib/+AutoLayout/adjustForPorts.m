function layout = adjustForPorts(layout)
% ADJUSTFORTEXT Adjust layout top/bottom positions to resize blocks to accomodate
%   their ports without disturbing the relative layout.
%
%   Inputs:
%       layout      As returned by external_lib.AutoLayout.getRelativeLayout.
%
%   Outputs:
%       layout      With modified position information.

    for j = 1:size(layout.grid,2) % for each column
        for i = 1:layout.colLengths(j) % for each non empty row in column
            block = layout.grid{i,j}.fullname; % block to resize
            pos = layout.grid{i,j}.position;
            [layout.grid{i,j}.position, yDisplace] = external_lib.AutoLayout.dimIncreaseForPorts(...
                block, pos, 'bot'); % Returns amount to move other blocks

            layout = external_lib.AutoLayout.vertMoveColumn(layout, i, j, yDisplace);
        end
    end
end
