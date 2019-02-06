function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_16(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('NAND', 16);
end