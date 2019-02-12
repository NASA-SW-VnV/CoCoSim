
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [inputs] = getSpecialInputsNames(parent, blk, type)
    srcPorts = blk.PortConnectivity(...
        arrayfun(@(x) strcmp(x.Type, type), blk.PortConnectivity));
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
