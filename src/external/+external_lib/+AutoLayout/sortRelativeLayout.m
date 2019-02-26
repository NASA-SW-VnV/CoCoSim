function grid = sortRelativeLayout(grid, colLengths)
% SORTRELATIVELAYOUT Sort blocks in grid within columns by their top positions.
%
%   Inputs:
%       grid        Format as defined in getRelativeLayout.
%       colLengths  Format as defined in getRelativeLayout.
%
%   Outputs:
%       grid        Same format, but sorted so that layout is accurate for
%                   relative vertical positions.

    for i = 1:size(grid,2) % for each column
        colMat = getColMatrix(i, grid);
        colMat = sortByTopPos(colMat);
        for j=1:colLengths(i) % for each non empty row in column
            grid{j,i} = colMat{j};
        end
    end
end

function sortedMat1D = sortByTopPos(mat1d)
% SORTBYTOPPOS Takes an unsorted matrix of blocks (format is important if some
%   spaces are empty) and returns a matrix of blocks sorted in the order they
%   appear in the block diagram.

    tops = [];
    len = 0;   % len represents the number of non-empty values in mat1d

    for i = 1:length(mat1d)
        if ~isempty(mat1d{i})
            pos = mat1d{i}.position;
            tops = [tops ; pos(2)];
            len = len + 1;
        else
            break
        end
    end
    [vals, order] = sort(tops);
    sortedMat1D = mat1d(order);

    for i = len + 1:length(mat1d)
        sortedMat1D{i} = [];
    end
end

function colMatrix = getColMatrix(colNum, mat2d)
% GETCOLMATRIX Takes a 2-D matrix and a column number (less than size(mat2d,2)) and
% returns a 1-D matrix of the values in the designated column (in the same order).

    for i = 1:size(mat2d,1)
        colMatrix{i} = mat2d{i, colNum};
    end
end