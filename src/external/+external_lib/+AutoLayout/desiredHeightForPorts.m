function desiredHeight = desiredHeightForPorts(block, varargin)
% DESIREDHEIGHTFORPORTS Determine a desirable block height to accomodate its ports.
%   Note: This function assumes blocks have not been rotated.
%
%   Inputs:
%       block           Full name of a block (char array).
%       varargin{1}     Desired space between ports. Default is 40.
%       varargin{2}     Desired space above/below the top/bottom ports of a block.
%                       Default is either 5 or 30, depending on the block.
%
%   Outputs:
%       desiredHeight   Block height required to accomodate its ports.

    ports = get_param(block, 'Ports');
    maxPorts = max(ports(1),ports(2));

    if nargin > 2
        buff = varargin{2};
    else
        if maxPorts > 1
            buff = 30; % Buffer above/below the top/bottom port of a block
        else
            % Allow small heights for blocks with a max of one in/outport
            buff = 5; % Buffer above/below the top/bottom port of a block
        end
    end

    if nargin >= 2
        pSpace = varargin{1}; % Desired spacing between ports
    else
        pSpace = 40; % Desired spacing between ports
    end

    desiredHeight = pSpace*(maxPorts-1) + 2*buff;
end