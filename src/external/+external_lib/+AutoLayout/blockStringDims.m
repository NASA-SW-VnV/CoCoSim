function [height, width] = blockStringDims(block, string)
% BLOCKSTRINGDIMS Find the height and width that a string has/would have
%   within block.
%
%   Inputs:
%       block   Fullname or handle of a Simulink block.
%       string  A character array.
%
%   Outputs:
%       height  Height of string if diplayed using the block's parameters.
%       width   Width of string if diplayed using the block's parameters.

    fontName = get_param(block, 'FontName');
    fontSize = get_param(block, 'FontSize');
    if fontSize == -1
        fontSize = get_param(bdroot(block), 'DefaultBlockFontSize');
    end
    dims = getTextDims(string, fontName, fontSize, get_param(block, 'Parent'));
    width = dims(1);
    height = dims(2);
end