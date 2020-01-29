function [node, external_nodes_i, opens, abstractedNodes] = get_conv(lus_backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    opens = {'conv'};
    abstractedNodes = {};
    if ~LusBackendType.isLUSTREC(lus_backend)
        abstractedNodes = {'DataType conversion Library'};
    end
    external_nodes_i = {};
    node = '';
end