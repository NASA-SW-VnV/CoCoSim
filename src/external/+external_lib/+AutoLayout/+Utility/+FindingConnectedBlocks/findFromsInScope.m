function froms = findFromsInScope(block)
% FINDFROMSINSCOPE Find all From blocks associated with a Goto block.
%
%   Inputs:
%       block   Goto block path name.
%
%   Outputs:
%       froms   From block path names.

    if isempty(block)
        froms = {};
        return
    end

    % Ensure block parameter is a valid Goto block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'Goto'));
    catch
        help(mfilename)
        froms = {};
        error('Block parameter is not a Goto block.');
    end

    tag = get_param(block, 'GotoTag');
    scopedTags = find_system(bdroot(block), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
    level = get_param(block, 'parent');
    tagVis = get_param(block, 'TagVisibility');

    % If there are no corresponding tags, Goto is assumed to be
    % local, and all local Froms corresponding to the tag are found
    if strcmp(tagVis, 'local')
        froms = find_system(level, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'SearchDepth', 1, ...
            'BlockType', 'From', 'GotoTag', tag);
        return
    % Goto is scoped
    elseif strcmp(tagVis, 'scoped');
        visibilityBlock = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findVisibilityTag(block);
        froms = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findGotoFromsInScope(visibilityBlock);
        blocksToExclude = find_system(get_param(visibilityBlock, 'parent'), 'LookUnderMasks', 'all', ...
            'FollowLinks', 'on', 'BlockType', 'Goto', 'GotoTag', tag);
        froms = setdiff(froms, blocksToExclude);
    else
        fromsToExclude = {};

        for i = 1:length(scopedTags)
            fromsToExclude = [fromsToExclude find_system(get_param(scopedTags{i}, 'parent'), 'LookUnderMasks', 'all', ...
                'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag)];
        end

        localGotos = find_system(bdroot(block), 'LookUnderMasks', 'all', 'BlockType', 'Goto', 'TagVisibility', 'local');
        for i = 1:length(localGotos)
            fromsToExclude = [fromsToExclude find_system(get_param(localGotos{i}, 'parent'), 'LookUnderMasks', 'all', ...
                'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag)];
        end

        froms = find_system(bdroot(block), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
            'BlockType', 'From', 'GotoTag', tag);
        froms = setdiff(froms, fromsToExclude);
    end
end
