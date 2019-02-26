function pos = setPositionAL(block, pos)
% SETPOSITIONAL Set block position. Use this function when setting positions in
%   AutoLayout in case we want to change this in some way later.
%
%   Inputs:
%       block   Block for which to change position.
%       pos     Position to set the block to.
%
%   Outputs:
%       pos     New position of the block.

    set_param(block, 'Position', pos);
    % Get the new position, since set_param won't always set it exactly to the position it is given
    pos = get_param(block, 'Position');
end