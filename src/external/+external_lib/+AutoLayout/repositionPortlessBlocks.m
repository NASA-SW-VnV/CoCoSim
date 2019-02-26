function portlessInfo = repositionPortlessBlocks(portlessInfo, layout, portless_rule, smallOrLargeHalf, sort_portless)
% REPOSITIONPORTLESSBLOCKS Reposition portless blocks to a side of the system.
%   Organize portless blocks into groups on the designated sides.
%
%   Inputs:
%       portlessInfo        As returned by getPortlessInfo.
%       layout              As returned by getRelativeLayout.
%       portless_rule       Rule by which portless blocks should be
%                           positioned. See PORTLESS_RULE in config.txt.
%       smallOrLargeHalf    Map relating blocks with the side of the system
%                           they should be placed on.
%       sort_portless       Determines how to sort the portless blocks
%                           after the side is determined. See SORT_PORTLESS
%                           in config.txt.
%
%   Outputs:
%       portlessInfo        Updated portlessInfo with new positions.

    ignorePortlessBlocks = true;
    [leftBound,topBound,rightBound,botBound] = sideExtremes(layout, portlessInfo, ignorePortlessBlocks);

    vertSpace = 20; % Space to leave between blocks vertically
    horzSpace = 20; % Space to leave between blocks horizontally

    if ~strcmp(sort_portless, 'none')
        portlessInfo = sortPortlessInfo(portlessInfo, sort_portless);
    end

    switch portless_rule
        case 'left'
            %         doCheck = false;
            portlessInfo = horzReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'left');
        case 'top'
            %         doCheck = false;1
            portlessInfo = vertReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'top');
        case 'right'
            %         doCheck = false;
            portlessInfo = horzReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'right');
        case 'bottom'
            %         doCheck = false;
            portlessInfo = vertReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'bottom');
        case 'same_half_vertical'
            %         doCheck = true;
            portlessInfo = vertReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'top');
            portlessInfo = vertReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'bottom');
        case 'same_half_horizontal'
            %         doCheck = true;
            portlessInfo = horzReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'left');
            portlessInfo = horzReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,'right');
        otherwise
            % Invalid portless_rule
            error(['portless_rule must be in the following ' ...
                '{''top'', ''left'', ''bot'', ''right'', ' ...
                '''same_half_vertical'', ''same_half_horizontal''}']);
    end
end

function newPortlessInfo = sortPortlessInfo(portlessInfo, sort_portless)
% NEWPORTLESSINFO Sort portlessInfo by the block parameter(s) designated by sort_portless.

    categories = {}; % Cell array of the different categories to put blocks in i.e. if sorting on block type there might be a 'SubSystem' or an 'Inport' category
    newPortlessInfo = {};

    for i = 1:length(portlessInfo) % for each portless block
        isNewType = ~AinB(getBlockCategory(portlessInfo{i}.fullname,sort_portless), categories);
        if isNewType % if the block's value for the sort_portless is new to categories

            % Record category
            categories{end+1} = getBlockCategory(portlessInfo{i}.fullname,sort_portless);
            newPortlessInfo{end+1} = portlessInfo{i}; % (have to add each portlessInfo to the new one once)
            for j = i+1:length(portlessInfo) % for remaining portless blocks
                if strcmp(getBlockCategory(portlessInfo{j}.fullname,sort_portless),categories{end}) % if parameter matches
                    % Add the portlessInfo
                    newPortlessInfo{end+1} = portlessInfo{j};
                end
            end % All of categories{end} should have been added now, so move on to find the next category
        end
    end
end

function cat = getBlockCategory(block,sort_portless)
    if strcmp(sort_portless, 'blocktype')
        cat = get_param(block,sort_portless);
    elseif strcmp(sort_portless, 'masktype_blocktype')
        params = strsplit('masktype_blocktype','_');
        cat = [get_param(block,params{1}), '_', get_param(block,params{2})];
    end
end

function portlessInfo = vertReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,vertSide)
% When editing this function also check horzReposPortless

    nextLeft = leftBound;

    if strcmp(vertSide, 'top')
        currRow = topBound - vertSpace;
        nextRow = topBound - vertSpace;
    elseif strcmp(vertSide, 'bottom')
        currRow = botBound + vertSpace;
        nextRow = botBound + vertSpace;
    end

    if ~strcmp(sort_portless,'none') && ~isempty(portlessInfo)
        oldCategory = getBlockCategory(portlessInfo{1}.fullname, sort_portless);
    end
    for i = 1:length(portlessInfo)
        block = portlessInfo{i}.fullname;

        flag = true; % Set flag to false to change row
        if ~strcmp(sort_portless,'none')
            newCategory = getBlockCategory(block, sort_portless);
            flag = strcmp(oldCategory, newCategory); % Check if block category changed
            % ^Change row when block category changes to sort
        end

        if strcmp(smallOrLargeHalf(block),vertSide)

            pos = portlessInfo{i}.position;
            width = pos(3) - pos(1);
            height = pos(4) - pos(2);

            if (nextLeft == leftBound || nextLeft + width <= rightBound) && flag
                % Same row
                left = nextLeft;
            else
                % New row
                currRow = nextRow;
                left = leftBound;
            end
            right = left + width;
            nextLeft = right + horzSpace;

            if strcmp(vertSide, 'top')
                bot = currRow;
                top = bot - height;
                nextRow = min(nextRow, top - vertSpace);
            elseif strcmp(vertSide, 'bottom')
                top = currRow;
                bot = top + height;
                nextRow = max(nextRow, bot + vertSpace);
            end

            portlessInfo{i}.position = [left top right bot];
        end

        if ~strcmp(sort_portless,'none')
            oldCategory = newCategory;
        end
    end
end

function portlessInfo = horzReposPortless(portlessInfo,smallOrLargeHalf,sort_portless,leftBound,topBound,rightBound,botBound,vertSpace,horzSpace,horzSide)
    % When editing this function also check vertReposPortless

    nextTop = topBound;

    if strcmp(horzSide, 'left')
        currCol = leftBound - horzSpace;
        nextCol = leftBound - horzSpace;
    elseif strcmp(horzSide, 'right')
        currCol = rightBound + horzSpace;
        nextCol = rightBound + horzSpace;
    end

    if ~strcmp(sort_portless,'none') && ~isempty(portlessInfo)
        oldCategory = getBlockCategory(portlessInfo{1}.fullname, sort_portless);
    end
    for i = 1:length(portlessInfo)
        block = portlessInfo{i}.fullname;

        flag = true; % Set flag to false to change column
        if ~strcmp(sort_portless,'none')
            newCategory = getBlockCategory(block, sort_portless);
            flag = strcmp(oldCategory, newCategory); % Check if block category changed
            % ^Change column when block category changes to sort
        end

        if strcmp(smallOrLargeHalf(block),horzSide)

            pos = portlessInfo{i}.position;
            width = pos(3) - pos(1);
            height = pos(4) - pos(2);

            if (nextTop == topBound || nextTop + height <= botBound) && flag
                % Same col
                top = nextTop;
            else
                % New col
                currCol = nextCol;
                top = topBound;
            end

            bot = top + height;
            nextTop = bot + vertSpace;

            if strcmp(horzSide, 'left')
                right = currCol;
                left = right - width;
                nextCol = min(nextCol, left - horzSpace);
            elseif strcmp(horzSide, 'right')
                left = currCol;
                right = left + width;
                nextCol = max(nextCol, right + horzSpace);
            end

            portlessInfo{i}.position = [left top right bot];
        end

        if ~strcmp(sort_portless,'none')
            oldCategory = newCategory;
        end
    end
end