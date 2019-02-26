function name = applyNamingConvention(handle)
% APPLYNAMINGCONVENTION Apply a naming convention to blocks and ports.
%   May be expanded to other elements in the future.
%
%   Inputs:
%       handle  Handle of the block/port. Block name is also accepted.
%
%   Outputs:
%       name    Name with convention applied to it.

    % Check handle argument
    try
        assert(~isempty(handle));
    catch
        error('Invalid handle.');
    end

    rows = size(handle, 1);
    cols = size(handle, 2);

    if (rows == 1 && cols == 1) || ischar(handle) % Scalar or string
        type = get_param(handle, 'Type');
        if strcmp(type, 'block')
            % Blocks
            oldName = getfullname(handle);
            if iscell(oldName)
                oldName = cell2mat(oldName);
            end
            name = strcat([oldName ':b']);
        elseif strcmp(type, 'port')
            % Block ports
            parName = get_param(handle, 'Parent');
            portType = get_param(handle, 'PortType');
            portNum = get_param(handle, 'PortNumber');
            if strcmp(portType, 'inport')
                name = [parName ':i' num2str(portNum)];
            elseif strcmp(portType, 'outport')
                name = [parName ':o' num2str(portNum)];
            else
                error('Ports other than inports and outports are not supported.');
            end
        end
    else % Vector
        name = cell(rows, cols);
        for i = 1:rows
            for j = 1:cols
                name(i,j) = {applyNamingConvention(handle(i,j))}; % Recurse
            end
        end
    end
end