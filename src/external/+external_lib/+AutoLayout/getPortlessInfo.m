function [portlessInfo, smallOrLargeHalf] = getPortlessInfo(portless_rule, systemBlocks, portlessBlocks)
% GETPORTLESSINFO Find the name and position about the portless blocks. For
%   position, also check which half of the system each block is in, relative
%   to the others (checks top/bottom vs. left/right half based on relevance
%   with portless_rule).
%
%   Inports:
%       portless_rule   Rule by which portless blocks should later be
%                       positioned. See PORTLESS_RULE in config.txt.
%       systemBlocks    List of all blocks in a system.
%       portlesBlocks   List of portless blocks in a system.
%
%   Outports:
%       portlessInfo        Struct of portless blocks' fullname and position.
%       smallOrLargeHalf    Map relating blocks with the side of the system
%                           they should be placed on.

    % For each case:
    % 1) Create a struct array portlessInfo which contains the name of the portless
    % blocks and has their position for the struct set to null.
    % 2) Create a map which specifies relative to where the portless blocks will be
    % placed.
    switch portless_rule
        case 'top'
            portlessInfo = struct('fullname', {}, ...
                'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                smallOrLargeHalf(portlessBlocks{i}) = 'top';
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        case 'left'
            portlessInfo = struct('fullname', {}, ...
                'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                smallOrLargeHalf(portlessBlocks{i}) = 'left';
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        case 'right'
            portlessInfo = struct('fullname', {}, ...
                'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                smallOrLargeHalf(portlessBlocks{i}) = 'right';
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        case 'same_half_vertical'
            [~,center] = systemCenter(systemBlocks);

            portlessInfo = struct('fullname', {}, ...
                        'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                bool = onSide(portlessBlocks{i}, center, 'top');
                if bool
                    smallOrLargeHalf(portlessBlocks{i}) = 'top';
                else
                    smallOrLargeHalf(portlessBlocks{i}) = 'bottom';
                end
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        case 'same_half_horizontal'
            [center,~] = systemCenter(systemBlocks);

            portlessInfo = struct('fullname', {}, ...
                        'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                bool = onSide(portlessBlocks{i}, center, 'top');
                if bool
                    smallOrLargeHalf(portlessBlocks{i}) = 'left';
                else
                    smallOrLargeHalf(portlessBlocks{i}) = 'right';
                end
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        case 'bottom'
            portlessInfo = struct('fullname', {}, ...
                'position', {});
            smallOrLargeHalf = containers.Map();

            for i = 1:length(portlessBlocks)
                smallOrLargeHalf(portlessBlocks{i}) = 'bottom';
                portlessInfo{end+1} = struct('fullname', portlessBlocks{i}, ...
                    'position', []);
            end
        otherwise
            % Invalid portless_rule
            error(['portless_rule must be in the following ' ...
                '{''top'', ''left'', ''bot'', ''right'', ' ...
                '''same_half_vertical'', ''same_half_horizontal''}']);
    end
end