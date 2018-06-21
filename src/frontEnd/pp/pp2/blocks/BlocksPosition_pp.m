function [  ] = BlocksPosition_pp( model, depth )
%BLOCKS_POSITION_PROCES try t change blocks position for graphical purpose.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear organize
limitedDepth = true;
if ~exist('depth', 'var')
    limitedDepth = false;
    depth = 100000;
end
%Take the list of all blocks that has no outport so they can be at one
%level. Blocks such Outports, displays ...
allBlocks = find_system(model,  'SearchDepth', 1);
levels_map =  [];
currentDepth = 0;
for i=2:length(allBlocks)
    currentDepth = currentDepth +1;
    try
        DstBlkH = get_param(allBlocks{i}, 'PortHandles');
    catch
        continue;
    end
    if isempty(DstBlkH.Outport)
        display_msg(...
            sprintf('organizing block "%s" and its linked blocks',allBlocks{i}),...
            MsgType.INFO, 'BlocksPosition_pp', '');
        levels_map = organize(get_param(allBlocks{i}, 'Handle'), 0, levels_map);
    end
    if strcmp(get_param(allBlocks{i}, 'BlockType'),'SubSystem')
        if (~limitedDepth) || (limitedDepth && currentDepth <= depth)
            BlocksPosition_pp( allBlocks{i} , depth);
        end
    end
    
end

end

%%
function levels_map = organize(block_handle, level, levels_map)


% this variable save all processed blocks to avoid loops,
persistent alreadyProcessed;

if isempty(alreadyProcessed)
    alreadyProcessed(1) = block_handle;
elseif ~ismember(block_handle, alreadyProcessed)
    alreadyProcessed(numel(alreadyProcessed) + 1) = block_handle;
else
    disp('***************')
    return;
end
if isempty(levels_map)
    levels_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
end
if ~isKey(levels_map, level)
    if isKey(levels_map, level - 1)
        last_level_pos =  levels_map(level - 1);
        levels_map(level) = [last_level_pos(1) - 200, 50,...
            last_level_pos(1) - 100, 100];
    else
        levels_map(level) = [1000, 50, 1050, 100];
    end
end

pos = get_param(block_handle, 'Position');
dx = pos(3) - pos(1);
dy = pos(4) - pos(2);

current_pos = levels_map(level);
left = current_pos(3) - dx;
top = current_pos(2);
right = current_pos(3);
bottom = current_pos(2) + dy;

set_param(block_handle, 'Position', [left, top, right, bottom]);
min_left = min(left, current_pos(1));

levels_map(level) = [min_left, bottom + 50, right, bottom + 100];

portHandles = get_param(block_handle, 'PortHandles');
srcBlocks = [];
inports = [ portHandles.Enable, portHandles.Trigger,...
    portHandles.Ifaction, portHandles.Reset, portHandles.Inport];
for i=1:numel(inports)
    l = get_param(inports(i), 'line');
    if l == -1
        continue;
    end
    src = get_param(l, 'SrcBlockHandle');
    if ismember(src, alreadyProcessed)
        continue;
    end
    if ~ismember(src, srcBlocks)
        srcBlocks(numel(srcBlocks) + 1) = src;
        display_msg(...
            sprintf('organizing block "%s" and its linked blocks',get_param(src, 'Name')),...
            MsgType.INFO, 'organize', '');
        levels_map = organize(src, level + 1, levels_map);
    end
    srcPortHandle = get_param(l, 'SrcPortHandle');
    sourceLine = get_param(srcPortHandle, 'line');
    distinations = get_param(sourceLine, 'DstPortHandle');
    for d=distinations'
        l = get_param(d, 'line');
        try delete(l); catch, end
        add_line(get_param(src, 'Parent'), srcPortHandle, d);
    end
    % reline the line
    
end

end