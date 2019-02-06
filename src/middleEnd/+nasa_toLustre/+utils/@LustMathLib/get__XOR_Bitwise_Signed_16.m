function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_16(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('XOR', 16);
end