function hasPorts = hasPorts(block)
% HASPORTS Check if a block has any ports.
%
%   Inputs:
%       block       Full name of a block. If a cell array is given, the first
%                   element is used.
%
%   Outputs:
%       hasPorts    Whether the block has one or more ports (1), or none (0).

    % Allow cell array input
    if iscell(block)
        block = block{1};
    end

    % The block has no ports if its parameter PortConnectivity is empty
    ports = get_param(block,'PortConnectivity');
    if isempty(ports)
        hasPorts = false;
    else
        hasPorts = true;
    end
end