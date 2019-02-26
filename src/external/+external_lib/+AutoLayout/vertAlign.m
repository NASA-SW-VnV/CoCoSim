function layout = vertAlign(layout)
% VERTALIGN Align blocks to facilitate the use of straight lines in connections
%   by repositioning blocks vertically. Currently only attempts to align blocks
%   which connect to a single block through an inport/outport.
%
%   Inputs:
%       layout          As returned by getRelativeLayout.
%
%   Outputs:
%       layout          With modified position information.

    % Figure out which blocks to try aligning.
    % NOTE: Currently requires the block to have specifically 1 port.
    % This should later at least account for 1 port on either side. Will
    % also need to update the while loop later as it assumes just 1 port.
    blocksToTryAlign = {}; % Record by indices in layout.grid
    for j = 1:size(layout.grid,2) % for each column
        for i = 1:layout.colLengths(j) % for each non empty row in column

            block1 = layout.grid{i,j}.fullname; % block to consider aligning
            ports1 = get_param(block1, 'Ports');
            portCon1 = get_param(block1, 'PortConnectivity');

            if sum(ports1) == 1 % has 1 port
                if ports1(1) == 1 || ... % has inport
                        (ports1(2) == 1 && length(portCon1(end).DstBlock) == 1) % has outport (non-branching)
                    % Alignment desired
                    blocksToTryAlign{end+1} = [i,j]; % Recording by layout.grid indices
                end
            end
        end
    end

    % Align blocks
    % Keep trying to align until no blocks are getting aligned (some blocks may
    % start in the way and later be out of the way). Avoid infinite loop by
    % removing blocks once they have been aligned.
    loop = true;
    while(loop)
        loop = false;
        for i = length(blocksToTryAlign):-1:1 % Reverse order to not mess up indices since items will be removed

            row = blocksToTryAlign{i}(1);
            col = blocksToTryAlign{i}(2);
            block1 = layout.grid{row,col}.fullname; % block to align

            ports1 = get_param(block1, 'Ports');
            portCon1 = get_param(block1, 'PortConnectivity');

            % Determine how much to shift the block
            if ports1(1) == 1
                block2 = portCon1(1).SrcBlock; % block to use as anchor
                ports2 = get_param(block2, 'Ports');
                portCon2 = get_param(block2, 'PortConnectivity');

                % endHeight: Position of the associated port on the other block
                % associated port #: #ports + 1 - #outports + n
                %                   end    + 1 - ports2(2) + portCon1(1).SrcPort
                %   (where the connection is with the nth outport of the other block)
                endHeight = portCon2(end+1-ports2(2)+portCon1(1).SrcPort).Position(2);

                startHeight = portCon1(1).Position(2);
                shamt = endHeight - startHeight; %shift amount
            elseif ports1(2) == 1
                block2 = portCon1(end).DstBlock; % block to use as anchor
                % ports2 = get_param(block2, 'Ports'); % not needed
                portCon2 = get_param(block2, 'PortConnectivity');

                % endHeight: Position of the associated port on the other block
                % associated port #: minimum port + m
                %                   1            + portCon1(end).DstPort
                %   (where the connection is with the mth inport of the other block)
                endHeight = portCon2(1+portCon1(end).DstPort).Position(2);

                startHeight = portCon1(end).Position(2);
                shamt = endHeight - startHeight; %shift amount
            end

            % If can move by the determined distance (i.e. no block obstruction),
            % then mark to move and remove from list to align.
            % Else leave in list to align
            doAlign = false; % Used to see if the variable has space to undergo the alignment
            curBounds = getPositionWithName(layout.grid{row,col}.fullname);
            if shamt < 0
                if row == 1
                    % Block has enough space to move
                    doAlign = true;
                    blocksToTryAlign(i) = [];
                else
                    blockBounds = getPositionWithName(layout.grid{row-1,col}.fullname);
                    if blockBounds(4) < curBounds(2) + shamt
                        % Block has enough space to move
                        doAlign = true;
                        blocksToTryAlign(i) = [];
                    end
                end
            elseif shamt > 0
                if row == layout.colLengths(col)
                    % Block has enough space to move
                    doAlign = true;
                    blocksToTryAlign(i) = [];
                else
                    blockBounds = getPositionWithName(layout.grid{row+1,col}.fullname);
                    if blockBounds(2) > curBounds(4) + shamt
                        % Block has enough space to move
                        doAlign = true;
                        blocksToTryAlign(i) = [];
                    end
                end
            else
                % No alignment needed
                blocksToTryAlign(i) = [];
            end

            % Physically do the alignment
            if doAlign
                %Align block
                curPos = layout.grid{row,col}.position;
                layout.grid{row,col}.position = [curPos(1), curPos(2) + shamt, curPos(3), curPos(4) + shamt];
                set_param(layout.grid{row,col}.fullname, 'Position', layout.grid{row,col}.position)

                % Continue loop
                loop = true;
            end
        end
    end
end