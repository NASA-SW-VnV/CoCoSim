function mem = findDataStoreMemory(block)
% FINDDATASTOREMEMORY Find the Data Store Memory block of a Data Store Read or
%   Write block.
%
%   Inputs:
%       block   Data Store Read or Write path name.
%
%   Outputs:
%       mem     Data Store Memory block path name.

    if isempty(block)
        mem = {};
        return
    end

    % Ensure input block is a valid Data Store Read/Write block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'DataStoreRead') || strcmp(blockType, 'DataStoreWrite'));
    catch
        help(mfilename)
        mem = {};
        error('Block parameter is not a Data Store Read or Write block.');
    end

    dataStoreName = get_param(block, 'DataStoreName');
    dataStoreMems = find_system(bdroot(block), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
    level = get_param(block, 'parent');
    currentLevel = '';

    % Level of the Data Store Read/Write being split into subsystem name tokens
    levelSplit = regexp(level, '/', 'split');

    for i = 1:length(dataStoreMems)
        % Get level of subsystem for the Data Store Memory
        memScope = get_param(dataStoreMems{i}, 'parent');
        memScopeSplit = regexp(memScope, '/', 'split');
        inter = memScopeSplit(ismember(memScopeSplit, levelSplit));
        % Check if the Data Store Memory is above the write in system hierarchy
        if (length(inter) == length(memScopeSplit))
            currentLevelSplit = regexp(currentLevel, '/', 'split');
            % If it is closest to the Read/Write, note that as the correct
            % scope for the Data Store Memory block
            if isempty(currentLevel) || length(currentLevelSplit) < length(memScopeSplit)
                currentLevel = memScope;
            end
        end
    end

    if ~isempty(currentLevel)
        mem = find_system(currentLevel, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'SearchDepth', 1, ...
            'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
        mem = mem{1};
    else
        mem = {};
    end
end
