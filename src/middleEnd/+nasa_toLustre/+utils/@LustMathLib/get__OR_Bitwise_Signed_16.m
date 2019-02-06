function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_16(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('OR', 16);
end