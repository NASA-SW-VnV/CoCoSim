function updateLayout(address, layout)
% UPDATELAYOUT Move blocks to their new positions designated by layout.
%
%   Inputs:
%       address         Simulink system name or path.
%       layout          As returned by getRelativeLayout.
%
%   Outputs:
%       N/A

    % Get blocknames and desired positions
    fullnames = {}; positions = {};
    for j = 1:size(layout.grid,2)
        for i = 1:layout.colLengths(j)
            fullnames{end+1} = layout.grid{i,j}.fullname;
            positions{end+1} = layout.grid{i,j}.position;
        end
    end

    % Move blocks to the desired positions
    moveBlocks(address, fullnames, positions);
end