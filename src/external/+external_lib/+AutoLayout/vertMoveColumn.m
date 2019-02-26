function layout = vertMoveColumn(layout, row, col, y)
% VERTMOVECOLUMN Vertically move blocks in col and below row in layout.grid
%   downward by y.
%
%   Inputs:
%       layout      As returned by getRelativeLayout.
%       row         Row number, below which blocks will be moved.
%       col         Column number, in whihch blocks will be moved.
%       y           Number of pixels to move blocks.
%
%   Outputs:
%       layout      With modified position information.

    j = col;
    for i = row + 1:layout.colLengths(j)
        layout.grid{i,j}.position(2) = layout.grid{i,j}.position(2) + y;
        layout.grid{i,j}.position(4) = layout.grid{i,j}.position(4) + y;
    end
end