function writes = findWritesInScope(block)
% FINDWRITESINSCOPE Find all the Data Store Writes associated with a Data
%   Store Read block.
%
%   Inputs:
%       block   Data Store Read block path name.
%
%   Outputs:
%       reads   Data Store Write block path names.

    if isempty(block)
        writes = {};
        return
    end

    % Ensure input is a valid Data Store Read block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'DataStoreRead'));
    catch
        help(mfilename)
        writes = {};
        error('Block parameter is not a Data Store Read block.');
    end

    dataStoreName = get_param(block, 'DataStoreName');
    memBlock = findDataStoreMemory(block);
    writes = findReadWritesInScope(memBlock);
    blocksToExclude = find_system(get_param(memBlock, 'parent'), ...
        'FollowLinks', 'on', 'BlockType', 'DataStoreRead', 'DataStoreName', dataStoreName);
    writes = setdiff(writes, blocksToExclude);
end