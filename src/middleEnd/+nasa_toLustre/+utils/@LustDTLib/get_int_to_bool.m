function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_bool(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getToBool('int');
end