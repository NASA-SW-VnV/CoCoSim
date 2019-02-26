function goto = findGotosInScope(block)
% FINDGOTOSINSCOPE Find the Goto block associated with a From block.
%
%   Inputs:
%       block   From block path name.
%
%   Outputs:
%       froms   Goto block path name.

    if isempty(block)
        goto = {};
        return
    end

    % Ensure block parameter is a valid From block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'From'));
    catch
        help(mfilename)
        goto = {};
        error('Block parameter is not a From block.');
    end

    tag = get_param(block, 'GotoTag');
    goto = find_system(get_param(block, 'parent'), 'LookUnderMasks', 'all','SearchDepth', 1,  ...
        'FollowLinks', 'on', 'BlockType', 'Goto', 'GotoTag', tag, 'TagVisibility', 'local');
    if ~isempty(goto)
        return
    end

    % Get the corresponding Gotos for a given From that are in the correct scope
    visibilityBlock = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findVisibilityTag(block);
    if isempty(visibilityBlock)
        goto = find_system(bdroot(block), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
            'BlockType', 'Goto', 'GotoTag', tag, 'TagVisibility', 'global');
        return
    end
    goto = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findGotoFromsInScope(visibilityBlock);
    blocksToExclude = find_system(get_param(visibilityBlock, 'parent'), 'LookUnderMasks', 'all', ...
        'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag);
    goto = setdiff(goto, blocksToExclude);
end
