function layout = adjustForText(layout)
% ADJUSTFORTEXT Adjust left/right positions of blocks to resize blocks to fit
%   their text without disturbing the relative layout.
%
%   Inputs:
%       layout      As returned by getRelativeLayout.
%
%   Outputs:
%       layout      With modified position information.

    for j = 1:size(layout.grid,2) % for each column
        largestX = 0; %Shift amount
        for i = 1:layout.colLengths(j) % for each non empty row in column
            block = layout.grid{i,j}.fullname; % block to resize
            pos = layout.grid{i,j}.position;
            [layout.grid{i,j}.position, xDisplace] = dimIncreaseForText(...
                block, pos, 'right'); % Returns amount to move other blocks
            if xDisplace > largestX
                largestX = xDisplace;
            end
        end

        layout = horzAdjustBlocks(layout, j, largestX);
    end
end