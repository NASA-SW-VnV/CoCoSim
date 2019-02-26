function bounds = getPositionWithName(block)
% GETPOSITIONWITHNAME Find the bounding box of a block accounting for where
%   its name appears if showing. Does not currently account for other block
%   parameters that might be showing.
%
%   Inputs:
%       block   SSimulink block name or handle.
%
%   Outputs:
%       bounds  Bounding box of the block. Returned in the format
%               [left, top, right, bottom].

    position = get_param(block, 'Position');
    bounds = position;
    if strcmp(get_param(block,'ShowName'),'on')
        blockWidth = position(3) - position(1);

        name = get_param(block, 'Name');
        [nameHeight, nameWidth] = blockStringDims(block, name);
        namePlace = get_param(block, 'NamePlacement');

        if nameWidth > blockWidth
            bounds(3) = bounds(3) + ceil(0.5*(nameWidth-blockWidth));
            bounds(1) = bounds(1) - ceil(0.5*(nameWidth-blockWidth));
        end

        if strcmp(namePlace, 'normal') % Assume it's on the bottom
            buffer = 3;
            bounds(4) = bounds(4) + (nameHeight + buffer);
        elseif strcmp(namePlace, 'alternate') % Assume it's on the top
            buffer = 3;
            bounds(2) = bounds(2) - (nameHeight + buffer);
        else
            error(['Unexpected block NamePlacement in ' mfilename]);
        end
    end
end