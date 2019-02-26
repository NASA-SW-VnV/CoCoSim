function layout = fixLabelOutOfBounds(layout)
% FIXLABELOUTOFBOUNDS Horizontally move blocks in the layout away from the
%   system's left bound if a block's name label extends past it.
%
%   Inputs:
%       layout  As returned by getRelativeLayout.
%
%   Outputs:
%       layout  With modified (left, right) position information for labels.

    for j = 1:size(layout.grid,2) % for each column
        largestX = 0;
        for i = 1:layout.colLengths(j) % for each non empty row in column
            pos = get_param(layout.grid{i,j}.fullname, 'Position');
            midXPos = (pos(3) + pos(1))/2;
            labelSize = getLabelSize(layout.grid{i,j}.fullname);
            xDisplace = (labelSize/2) - midXPos;
            if xDisplace > 0
                if xDisplace > largestX
                    largestX = xDisplace;
                end
            end
        end
        horzAdjustBlocks(layout, j-1, largestX);
    end
end

function labelSize = getLabelSize(block)
% GETLABELSIZE Get the size of a block's label, because it can create an offset
% from where AutoLayout places it initially and we don't want to take that into account.

    if strcmp(get_param(block, 'ShowName'), 'on')
        [~, labelSize] = blockStringDims(block, get_param(block, 'Name'));
    else
        labelSize = 0;
    end
end