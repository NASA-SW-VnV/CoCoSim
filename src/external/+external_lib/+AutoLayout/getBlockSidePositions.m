function sidePositions = getBlockSidePositions(blocks, side)
% GETBLOCKSIDEPOSITIONS Find the *unique* block positions for a given side
%   of a set of blocks.
%
%   Inputs:
%       blocks          Cell array of the full names of block(s).
%                       If a cell array is given for one of the block names,
%                       the first element is used.
%
%       side            Number respesenting the following:
%                           1 - Left
%                           2 - Top
%                           3 - Right
%                           4 - Bottom
%                           5 - Midpoint between results of 1 and 3
%                           6 - Midpoint between results of 2 and 4
%
%   Outputs:
%       sidePositions   Vector of unique doubles for the positions.

    % Calculated the selected side position based on the side selected
    if side == 5
        sidePositions = [];
        for i = 1:length(blocks)
            if iscell(blocks{i})
                blocks{i} = char(blocks{i});
            end
            pos = get_param(blocks{i}, 'Position');
            midX = (pos(1) + pos(3)) / 2;
            if ~ismember(midX, sidePositions)
                sidePositions = [sidePositions, midX];
            end
        end

    elseif side == 6
        sidePositions = [];
        for i = 1:length(blocks)
            if iscell(blocks{i})
                blocks{i} = char(blocks{i});
            end
            pos = get_param(blocks{i}, 'Position');
            midY = (pos(2) + pos(4)) / 2;
            if ~ismember(midY, sidePositions)
                sidePositions = [sidePositions, midY];
            end
        end

    else
        sidePositions = [];
        for i = 1:length(blocks)
            if iscell(blocks{i})
                blocks{i} = char(blocks{i});
            end
            pos = get_param(blocks{i}, 'Position');
            if ~ismember(pos(side), sidePositions)
                sidePositions = [sidePositions , pos(side)];
            end
        end
    end
end