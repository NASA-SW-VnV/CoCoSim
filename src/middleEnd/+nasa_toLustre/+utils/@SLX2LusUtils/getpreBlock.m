
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% get pre block for specific port number
function [src, srcPort] = getpreBlock(parent, blk, Port)

    if ischar(Port)
        % case of Type: ifaction ...
        srcBlk = blk.PortConnectivity(...
            arrayfun(@(x) strcmp(x.Type, Port), blk.PortConnectivity));
    else
        srcBlks = blk.PortConnectivity(...
            arrayfun(@(x) ~isempty(x.SrcBlock), blk.PortConnectivity));
        srcBlk = srcBlks(Port);
    end
    if isempty(srcBlk)
        src = [];
        srcPort = [];
    else
        % Simulink srcPort starts from 0, we add one.
        srcPort = srcBlk.SrcPort + 1;
        srcHandle = srcBlk.SrcBlock;
        src = get_struct(parent, srcHandle);
    end
end
