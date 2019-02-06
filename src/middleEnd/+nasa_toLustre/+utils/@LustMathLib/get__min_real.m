function [node, external_nodes_i, opens, abstractedNodes] = get__min_real(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getMinMax('min', 'real');
end