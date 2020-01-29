%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_32(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = getBitwiseSigned('XOR', 32);
end
