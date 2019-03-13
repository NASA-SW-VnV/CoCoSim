function visBlock = findVisibilityTag(block)
% FINDVISIBILITYTAG Find the Goto Visibility Tag block associated with a
%   scoped Goto or From block.
%
%   Inputs:
%       block     Scoped Goto or From block path name.
%
%   Outputs:
%       visBlock  Goto Tag Visibility block path name.

    if isempty(block)
        visBlock = {};
        return
    end

    % Ensure input is a valid Goto or From block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'Goto') || strcmp(blockType, 'From'));
    catch
        help(mfilename)
        visBlock = {};
        error('Block parameter is not a Goto or From block.');
    end

    tag = get_param(block, 'GotoTag');
    scopedTags = find_system(bdroot(block), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
    level = get_param(block, 'parent');
    levelSplit = regexp(level, '/', 'split');

    currentLevel = '';

    % Find the Goto Tag Visibility block that is the closest, but above the
    % block, in the subsystem hierarchy by comparing their addresses
    for i = 1:length(scopedTags)
        % Get the level of tag visibility block
        tagScope = get_param(scopedTags{i}, 'parent');
        tagScopeSplit = regexp(tagScope, '/', 'split');
        inter = tagScopeSplit(ismember(tagScopeSplit, levelSplit));

        % Check if it is above the block
        if (length(inter) == length(tagScopeSplit))
            currentLevelSplit = regexp(currentLevel, '/', 'split');
            % If it is the closest to the Goto/From, note that as the correct
            % scope for the visibility block
            if isempty(currentLevel) || length(currentLevelSplit) < length(tagScopeSplit)
                currentLevel = tagScope;
            end
        end
    end

    % If the Goto Visibility Tag was found, return it, otherwise, return nothing
    if ~isempty(currentLevel)
        visBlock = find_system(currentLevel, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
            'SearchDepth', 1, 'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
        visBlock = visBlock{1};
    else
        visBlock = {};
    end
end
