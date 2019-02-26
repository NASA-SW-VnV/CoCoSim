function srcPorts = getSrcPorts(object)
% GETSRCPORTS Gets the outports that act as sources for a given block or dst port.
%
%   Input:
%       object      Name/handle of a block or a port handle.
%
%   Output:
%       srcPorts    Handles of source ports of the object.

    if strcmp(get_param(object, 'Type'), 'block')
        block = object;
        lines = get_param(block, 'LineHandles');
        lines = lines.Inport;
    elseif strcmp(get_param(object, 'Type'), 'port')
        port = object;
        lines = get_param(port, 'Line');
    else
        error(['Error: ' mfilename 'expected object type to be ''block'' or ''port'''])
    end

    srcPorts = [];
    for i = 1:length(lines)
        if lines(i) ~= -1
            srcPorts(end+1) = get_param(lines(i), 'SrcPortHandle');
        end
    end
end