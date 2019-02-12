
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get block inputs names. E.g subsystem taking input signals from differents blocks.
% We need to go over all linked blocks and get their output names
% in the corresponding port number.
% Read PortConnectivity documentation for more information.
function [inputs] = getBlockInputsNames(parent, blk, Port)
    % get only inports, we don't take enable/reset/trigger, outputs
    % ports.
    srcPorts = blk.PortConnectivity(...
        arrayfun(@(x) ~isempty(x.SrcBlock) ...
        &&  ~isempty(str2num(x.Type)) , blk.PortConnectivity));
    if nargin >= 3 && ~isempty(Port)
        srcPorts = srcPorts(Port);
    end
    inputs = {};
    for b=srcPorts'
        srcPort = b.SrcPort;
        srcHandle = b.SrcBlock;
        src = get_struct(parent, srcHandle);
        if isempty(src)
            continue;
        end
        n_i = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
        inputs = [inputs, n_i];
    end
end
