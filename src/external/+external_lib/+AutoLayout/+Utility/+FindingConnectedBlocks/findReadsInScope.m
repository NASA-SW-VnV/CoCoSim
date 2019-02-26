function reads = findReadsInScope(block)
% FINDREADSINSCOPE Find all the Data Store Read blocks associated with a Data
%   Store Write block.
%
%   Inputs:
%       block   Data Store Write block path name.
%
%   Outputs:
%       reads   Data Store Read block path names.

    if isempty(block)
        reads = {};
        return
    end

    % Ensure input is a valid Data Store Write block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'DataStoreWrite'));
    catch
        help(mfilename)
        reads = {};
        error('Block parameter is not a Data Store Write block.');
    end

    dataStoreName = get_param(block, 'DataStoreName');
    memBlock = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findDataStoreMemory(block);
    reads = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findReadWritesInScope(memBlock);
    blocksToExclude = find_system(get_param(memBlock, 'parent'), 'LookUnderMasks', 'all', 'FollowLinks', ...
        'on', 'BlockType', 'DataStoreWrite', 'DataStoreName', dataStoreName);
    reads = setdiff(reads, blocksToExclude);
end
