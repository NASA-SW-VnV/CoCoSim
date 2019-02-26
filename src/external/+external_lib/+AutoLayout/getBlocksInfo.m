function blocksInfo = getBlocksInfo(sys)
% GETBLOCKSINFO Get a struct with name and position information of all blocks
%   in a system.
%
%   Input:
%       sys     System address for which to get blocksInfo.
%
%   Outputs:
%       blocksInfo              Struct of data representing current block data.
%       blocksInfo(i).fullname  Fullname of a block.
%       blocksInfo(i).position  Position of a block.

    % Get blocks in sys
    blocks = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1);
    blocks = blocks(2:end); % Remove sys

    % Add names to struct
    blocksInfo = struct('fullname', blocks);

    % Add positions to struct
    for i = 1:length(blocks)
        pos = get_param(blocks{i}, 'Position');
        blocksInfo(i).position = pos;
    end
end
