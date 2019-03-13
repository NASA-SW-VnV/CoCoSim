function dg  = systemToDigraph(sys)
% SYSTEMTODIGRAPH Create a digraph out of the subsystem. Takes Simulink blocks
%   as nodes and their singal line connections as edges. Weights are the
%   default 1.
%
%   Inputs:
%       sys     Path of the system.
%
%   Outputs:
%       dg      Digraph representing the system.

    % Check first input
    try
        assert(ischar(sys));
    catch
        error('A string to a valid Simulink (sub)system must be provided.');
    end

    try
        assert(bdIsLoaded(bdroot(sys)));
    catch
        error('Simulink system provided is invalid or not loaded.');
    end

    % Get nodes
    nodes = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', '1', 'FindAll','off', 'Type', 'block');
    nodes(strcmp(nodes, sys), :) = [];  % If sys is a subsysttem, remove itself from the list
    numNodes = length(nodes);
    nodes = nodes(length(nodes):-1:1); % This seems to help the layout in the usual case

    % Get neighbour data
    param = cell(size(nodes));
    [param{:}] = deal('PortConnectivity');
    allPorts = cellfun(@get_param, nodes, param, 'un', 0);

    % Construct adjacency matrix
    % Each row and column pertains to a unique block
    % A value of '1' in an entry indicates that the two blocks (indicated by the
    % column and row) are adjacent to each other because the one of the row block's output
    % is connected to one of the column block's input
    A = zeros(numNodes);

    % Populate adjacency matrix
    % For each block, check which block it is connected to by checking the
    % block(s) it is connected to by filling the adjacency matrix
    for i = 1:numNodes
        data = allPorts{i};
        neighbours = [data.DstBlock];
        if ~isempty(neighbours)
            for j = 1:length(neighbours)
                n = getfullname(neighbours(j));
                [row,~] = find(strcmp(nodes, n));
                A(i,row) = true;
            end
        end
    end
    nodes = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(nodes);
    dg = digraph(A, nodes);
end
