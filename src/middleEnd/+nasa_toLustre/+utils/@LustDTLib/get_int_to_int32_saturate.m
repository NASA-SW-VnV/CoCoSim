function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int32_saturate(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('int32');
end