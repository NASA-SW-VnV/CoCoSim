function [srcs, srcPositions, didMove] = arrangeSources(blk, doMove)
% ARRANGESOURCES Finds sources of a block and swaps their vertical positions to
%   be ordered with respect to ports.
%
%   If there are branches or if a source has multiple outports, then no arranging
%   will be attempted, but positions to rearrange them will still be given as output.
%
%   Inputs:
%       blk     Simulink block fullname or handle.
%       doMove  Whether to move the blocks (1) or not (0).
%               If not, position information required to do the move is still returned.
%
%   Outputs:
%       srcs            Cell array of source block name.
%       srcPositions    Array of positions to move the srcs to.
%       didMove         Whether the blocks were moved (1) or not (0).
%                       Note: If doMove is false, didMove will always be false.
%                       If doMove is true, didMove may still be false as a
%                       result of branches/excessive ports (described above).
%
% Assumes blocks use the tradional block rotation, with inports on the left,
% and outports on the right.

    % TODO: Add support for triggers and if actions

    % Find desired order
    ph = get_param(blk, 'PortHandles');
    in = ph.Inport;
    len = length(in);
    orderedSrcs = cell(1, len);
    positions = zeros(len,4);
    tops = zeros(len,1);
    for i = 1:length(in)
        lh = get_param(in(i), 'Line');
        src = get_param(lh, 'SrcPortHandle');
        orderedSrcs{i} = get_param(src, 'Parent');

        srcph = get_param(orderedSrcs{i}, 'PortHandles');
        srcout = srcph.Outport;
        if isBranching(lh)
            doMove = false;
        end
        if length(srcout) > 1
            doMove = false;
        end

        positions(i,:) = get_param(orderedSrcs{i}, 'Position');
        tops(i) = positions(i, 2);
    end

    % Get old order
    newTops = sort(tops);

    % Use old order to swap top positions to place in the desired order
    newPositions = zeros(len,4);
    for j = 1:len %length(newTops)
        newTop = newTops(j);
        newBot = newTops(j) + positions(j,4) - positions(j,2);
        newPositions(j,:) = [positions(j,1), newTop, positions(j,3), newBot];
    end

    srcs = orderedSrcs;
    srcPositions = newPositions;

    if doMove
        % Set positions
        for j = 1:len %length(srcs)
            set_param(srcs{j}, 'Position', srcPositions(j, :))
        end
        didMove = true;
    else
        didMove = false;
    end
end