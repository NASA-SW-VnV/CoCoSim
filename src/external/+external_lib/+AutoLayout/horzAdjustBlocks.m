function layout = horzAdjustBlocks(layout, col, x)
% HORZADJUSTBLOCKS Horizontally move blocks in the layout, to the right of
%   the column, right by x.
%
%   Inputs:
%       layout          As returned by getRelativeLayout.
%       col             Column number, to the left of which blocks will not be moved.
%       x               Number of pixels to move blocks.
%
%   Outputs:
%       layout      With modified (left, right) position information.

    for j = col + 1:size(layout.grid,2)
        for i = 1:layout.colLengths(j)
            pos = layout.grid{i,j}.position;
            layout.grid{i,j}.position = [pos(1) + x, pos(2), pos(3) + x, pos(4)];
        end
    end
end