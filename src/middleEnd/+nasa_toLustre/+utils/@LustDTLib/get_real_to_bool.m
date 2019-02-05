function [node, external_nodes_i, opens, abstractedNodes] = get_real_to_bool(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getToBool('real');
end