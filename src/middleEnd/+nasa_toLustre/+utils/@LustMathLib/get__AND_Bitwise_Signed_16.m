function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_16(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('AND', 16);
end