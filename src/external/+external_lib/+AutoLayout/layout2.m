function layout = layout2(address, layout, systemBlocks)
% LAYOUT2 Performs a series of operations to further improve the layout
% from external_lib.AutoLayout.AutoLayout. The functionality it provides is listed below roughly 
% ordered with when it is done in this function.
%   Moves inputs and outputs to the outsides when it is easy (and not messy) to do so
%   Adjusts the vertical spacing between close blocks
%   Keeps labels on screen if they went off to the left
%   Expands small blocks by extending their right side
%   Adjusts spacing between blocks horizontally to be more reasonable
%   Redraws lines,
%       first uses the same method as in initLayout,
%       then prevents/removes diagonal lines,
%       then fixes a case where the autorouting isn't very good,
%       then fixes lines going over blocks,
%       and then fixes overlapping between vertical segments of lines
%   Places blocks with no ports (such as Data Store Memory blocks) along the top or bottom of the system horizontally
%       It chooses which half the system to place the block in based on the half it started in
%
%   Inputs:
%       address         Simulink system name or path.
%       systemBlocks    List of blocks in address.
%
%   Updates:
%       layout          Input in the same format as returned by 
%                       external_lib.AutoLayout.getRelativeLayout. Returned according to the
%                       operations performed in this function.

    % Adjust the spacing between adjacent blocks in columns of layout.grid
    layout = adjustColVertSpacing(layout);
    %Update block positions according to layout
    external_lib.AutoLayout.updateLayout(address, layout);

    % Shift everything right if any label is too far left
    layout = external_lib.AutoLayout.fixLabelOutOfBounds(layout);
    %Update block positions according to layout
    external_lib.AutoLayout.updateLayout(address, layout);

    % Enlarge blocks to fit strings in them
    %layout = fixBlockSize(layout);

    % Make lines reasonable
    external_lib.AutoLayout.redraw_lines(address,'autorouting','on');

    systemLines = find_system(address, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Line');
    colDims = getColumnDimensions(layout);
    vSegs = getVSegs(systemLines);

    % Adjust net horizontal space between columns in blocksMatrix
    layout = adjustHorzSpacing(layout, vSegs, colDims);
    %Update block positions according to layout
    external_lib.AutoLayout.updateLayout(address, layout);
    external_lib.AutoLayout.redraw_lines(address,'autorouting','on');

    systemLines = find_system(address, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Line'); % can I just do get_param(address,'Lines')?
    vSegs = getVSegs(systemLines);

    % Prevent cases where lines become diagonal lines when fixVSegs runs later
    external_lib.AutoLayout.preventDiagVSegs(systemLines);

    % Fix any remaining diagonal lines
    external_lib.AutoLayout.fixDiagonalLines(systemLines);

    % Fix a specific problem with redraw_lines
    fixRedrawLinesOvershoot(vSegs) % This doesn't preserve correctness of vSegs values

    systemLines = find_system(address, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Line');
    systemBlocks = find_system(address, 'LookUnderMasks', 'all','SearchDepth',1);
    systemBlocks = systemBlocks(2:end);

    % Prevent lines from travelling over a block to get the ports on top
    external_lib.AutoLayout.fixLineOverBlock(systemLines, systemBlocks);

    systemLines = find_system(address, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Line');
    colDims = getColumnDimensions(layout);
    vSegs = getVSegs(systemLines);

    % Reorganize the placements of vertical line segments in the system
%     spaceVSegs(vSegs, colDims); % Commented out for now since it can
%     cause diagonal lines

    % Place blocks that have no ports in a line along top or bottom horizontally
    % depending on where they were initially in the system
%     placePortlessBlocks(address, portlessInfo, blocksMatrix, colLengths, 'top', false);
%     placePortlessBlocks(address, portlessInfo, blocksMatrix, colLengths, 'bottom', false);
end

function fixRedrawLinesOvershoot(vSegs)
% Sometimes the redraw_lines function will cause a line to go further
% than it should and then goes back to where it should have been
% (it doesn't seem to improve line crossings).
% This function merges the vertical segment of the overshoot
% with a later vertical segment
% (this isn't expected to fix a lot of cases, just a few specific ones).

    % This doesn't guarantee preservation of the validity of vSegs
    for i = 1:length(vSegs)
        if vSegs{i}.pointsInLine(1, 1) < vSegs{i}.pointsInLine(end, 1) && ...
                vSegs{i}.pointsInLine(end, 1) < vSegs{i}.x && ...
                vSegs{i}.pointIndex2 < size(vSegs{i}.pointsInLine, 1)
            if i < length(vSegs)
                if vSegs{i}.line == vSegs{i+1}.line
                    % Move vSegs{i} to vSegs{i+1} and merge them
                    oldPoints = vSegs{i}.pointsInLine;
                    newPoints = [];
                    indexA = vSegs{i}.pointIndex1;
                    indexB = vSegs{i+1}.pointIndex1;
                    for j = 1:indexA - 1
                        newPoints = [newPoints; oldPoints(j,:)];
                    end
                    y = oldPoints(indexA, 2);
                    x = oldPoints(indexB, 1);
                    newPoints = [newPoints; x,y];

                    for j = indexB + 1:length(oldPoints)
                        newPoints = [newPoints; oldPoints(j,:)];
                    end

                    % Merge vSegs
                    set_param(vSegs{i+1}.line,'Points', newPoints); % Move points of line

                    % Keep vSegs{i+1} accurate for the following iterations
                    % (vSegs{i} doesn't need to since this function doesn't
                    % guarantee vSegs to stay correct
                    % vSegs{i} would be identical to vSegs{i+1})
                    vSegs{i+1}.pointsInLine = newPoints;
                    vSegs{i+1}.pointIndex1 = indexA;
                    vSegs{i+1}.pointIndex2 = indexA + 1;
                    vSegs{i+1} = updateVSeg(vSegs{i+1});
                end
            end
        end
    end
end

function spaceVSegs(vSegs, colDims)
% Re-places vSegs, evenly spacing them between the columns of blocks

    for i = 2:length(colDims) %for each column after first
        freeSpace = colDims{i}(1) - colDims{i-1}(2);
        if freeSpace > 0

            % Get vertical segments from anywhere between left side of previous
            % column and the left side of the current column.
            % If this code gets changed also change the equivalent part of adjustColWidths!
            tempVSegs = vSegsInRange(vSegs, colDims{i-1}(1), colDims{i}(1));
            arrangeVSegs(tempVSegs, colDims{i-1}(2), colDims{i}(1));
        else
            disp('Could not improve arrangement of vertical line segments within given space.')
        end
    end
end

function arrangeVSegs(vSegs, leftBound, rightBound)
% Arranges vSegs evenly between leftBound and rightBound

    vSegs = sortVSegs(vSegs); %So that they can be rearranged somewhat logically

    for i = 1:length(vSegs)
        xnew = leftBound + (((rightBound - leftBound)*i)/(length(vSegs) + 1));
        index1 = vSegs{i}.pointIndex1;
        index2 = vSegs{i}.pointIndex2;
        vSegs{i}.pointsInLine(index1,1) = xnew;
        vSegs{i}.pointsInLine(index2,1) = xnew;

        set_param(vSegs{i}.line,'Points', vSegs{i}.pointsInLine); % Move points
        vSegs{i} = updateVSeg(vSegs{i});
    end
end

function vSegs = sortVSegs(vSegs)
% Sorts vertical line segments, vSegs, giving priority to lowest x value,
% and secondary priority to largest ymax value
% no third level of priority is applied

    % Sort vSegs from smallest x to largest x
    xVals = [];
    for i = 1:length(vSegs)
        xVals(end + 1) = vSegs{i}.x;
    end
    [~, orderX] = sort(xVals);
    vSegs = vSegs(orderX);

    % Maintain order of smallest x to largest x,
    % Break ties by placing larger ymax earlier
    unSortedY = true;
    while unSortedY
        unSortedY = false;
        for i = 2:length(vSegs)

            % Don't break the previous sorting
            if vSegs{i}.x == vSegs{i-1}.x
                if vSegs{i-1}.ymax < vSegs{i}.ymax
                    unSortedY = true;

                    temp = vSegs{i-1};
                    vSegs{i-1} = vSegs{i};
                    vSegs{i} = temp;
                end
            end

        end
    end
end

function layout = adjustColVertSpacing(layout)
% Expands space between blocks within columns of blocks if less than a minimum

    for j = 1:size(layout.grid, 2) % for each column
        pos1 = get_param(layout.grid{1,j}.fullname, 'Position');
        for i = 1:layout.colLengths(j) - 1 % for each non-empty row in column except last
            pos2 = get_param(layout.grid{i+1, j}.fullname, 'Position');
            freeSpace = pos2(2) - pos1(4);

            string = layout.grid{i, j}.fullname;
            [minSpace, ~] = external_lib.AutoLayout.blockStringDims(layout.grid{i, j}.fullname, string);

            if freeSpace < minSpace
                adjustment = minSpace - freeSpace;
                layout = external_lib.AutoLayout.vertMoveColumn(layout, i, j, adjustment);
            end

            pos1 = pos2;
        end
    end
end

function layout = adjustHorzSpacing(layout, vSegs, colDims)
% Expands space between columns of blocks if less than a minimum determined
% by the number of vertical segments in that space.

    minSpacePerVSeg = 20; % Min desired amount of space per vertical segment in the freeSpace

    for i = 2:length(colDims) % For each column after first
        freeSpace = colDims{i}(1) - colDims{i-1}(2);

        % Get vertical segments from anywhere between left side of previous
        % column and the left side of the current column.
        % If this gets changed also change the equivalent part of spaceVSegs!
        tempVSegs = vSegsInRange(vSegs, colDims{i-1}(1), colDims{i}(1));
        minSpace = minSpacePerVSeg * length(tempVSegs);
        if freeSpace < minSpace
            adjustment = minSpace - freeSpace;
            layout = external_lib.AutoLayout.horzAdjustBlocks(layout, i-1, adjustment);
        end
    end
end

function vSegs = vSegsInRange(vSegs, leftBound, rightBound)
% Find all vertical line segments among vSegs that lie between leftBound and rightBound

    tempVSegs = {};
    for i = 1:length(vSegs)
        if leftBound <= vSegs{i}.x && vSegs{i}.x <= rightBound
            tempVSegs{end + 1} = vSegs{i};
        end
    end
    vSegs = tempVSegs;
end

function colDims = getColumnDimensions(layout)
% Returns the maximum positions of blocks on the x-axis for each column in blocksMatrix
%   colDims{#} = [largestLeftPosition, largestRightPosition]

    colDims = {};
    for j = 1:size(layout.grid, 2) % For columns in blocksMatrix
        lowestLeft = 32767; % Maximum coordinate in Simulink
        largestRight = 0;
        for i = 1:layout.colLengths(j) % For each non-empty in column
            if lowestLeft > external_lib.AutoLayout.getBlockSidePositions({layout.grid{i,j}.fullname}, 1) % 1->left side
                lowestLeft = external_lib.AutoLayout.getBlockSidePositions({layout.grid{i,j}.fullname}, 1);
            end
            if largestRight < external_lib.AutoLayout.getBlockSidePositions({layout.grid{i,j}.fullname}, 3) % 3->right side
                largestRight = external_lib.AutoLayout.getBlockSidePositions({layout.grid{i,j}.fullname}, 3);
            end
        end
        colDims{j} = [lowestLeft, largestRight];
    end
end

function vSegs = getVSegs(lines)
%   vSegs{#} has:
%       x - the x coordinate of the vertical segment
%       ymin - the minimum y coordinate of the vertical segment
%       ymax - the maximum y coordinate of the vertical segment
%       point1 - first point in the vertical segment
%       point2 - second point in the vertical segment
%       line - the handle of the line this vertical segment is apart of
%       pointsInLine - all points in line
%       pointIndex1 - point1's index in line
%       pointIndex2 - point2's index in line

    vSegs = {};
    linePoints = external_lib.AutoLayout.getAllLinePoints(lines);
    for i = 1:length(linePoints) % For all lines
        for j = 2:size(linePoints{i}, 1) % For all points after first in line
            points = linePoints{i};
            xnow = points(j, 1);
            xold = points(j-1, 1);
            if xnow == xold
                ynow = points(j, 2);
                yold = points(j-1, 2);
                if ynow ~= yold % Wouldn't be considered a vertical line if it had no length
                    ymin = (ynow < yold) * ynow + (yold < ynow) * yold;
                    ymax = (ynow > yold) * ynow + (yold > ynow) * yold;

                    vSegs{end+1} = struct( ...
                        'x', xnow, ...
                        'ymin', ymin, ...
                        'ymax', ymax, ...
                        'point1', points(j-1, :), ...
                        'point2', points(j,:), ...
                        'line', lines(i), ...
                        'pointsInLine', points, ...
                        'pointIndex1', j-1, ...
                        'pointIndex2', j);
                end
            end
        end
    end
end

function vSeg = updateVSeg(vSeg)
% Returns an updated vSeg.
% The following properties are assumed to already be up to date:
%   vSeg.line,
%   vSeg.pointsInLine,
%   vSeg.pointIndex1,
%   vSeg.pointIndex2

    vSeg.x = vSeg.pointsInLine(vSeg.pointIndex1, 1);
    y1 = vSeg.pointsInLine(vSeg.pointIndex1, 2);
    y2 = vSeg.pointsInLine(vSeg.pointIndex2, 2);
    vSeg.ymin = (y1 < y2) * y1 + (y2 < y1) * y2;
    vSeg.ymax = (y1 > y2) * y1 + (y2 > y1) * y2;
    vSeg.point1 = vSeg.pointsInLine(vSeg.pointIndex1, :);
    vSeg.point2 = vSeg.pointsInLine(vSeg.pointIndex2, :);
end
