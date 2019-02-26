function setNamePlacements(blocks, varargin)
% SETNAMEPLACEMENTS Set the placement of names for Simulink blocks.
%   Default will place names along the bottom of the block.
%
%   Inputs:
%       blocks      Cell array of blocks to use to find segments.
%       varargin    Character array indicating where to place a block's name
%                   with respect to the block. Options correspond with the
%                   'NamePlacement' block property, i.e., 'normal' (default)
%                   and 'alternate'.
%
%   Outputs:
%       N/A
%
%   Example:
%       external_lib.AutoLayout.GeneralPurpose.setNamePlacements(gcbs, 'normal')
%       external_lib.AutoLayout.GeneralPurpose.setNamePlacements(gcbs, 'alternate')

    if nargin > 1
        namePlacement = varargin{1};
    else
        namePlacement = 'normal';
    end

    for i = 1:length(blocks)
        set_param(blocks{i}, 'NamePlacement', namePlacement);
    end
end
