function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_32(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('NAND', 32);
end