function updatePortless(address, portlessInfo)
% UPDATEPORTLESS Move blocks to their new positions designated by portlessInfo.
%
%   Inputs:
%       address         Simulink system name or path.
%       portlessInfo    As returned by getPortlessInfo.
%
%   Outputs:
%       N/A

    % Get blocknames and desired positions
    fullnames = {}; positions = {};
    for i = 1:length(portlessInfo)
        fullnames{end+1} = portlessInfo{i}.fullname;
        positions{end+1} = portlessInfo{i}.position;
    end

    % Move blocks to the desired positions
    moveBlocks(address, fullnames, positions);
end