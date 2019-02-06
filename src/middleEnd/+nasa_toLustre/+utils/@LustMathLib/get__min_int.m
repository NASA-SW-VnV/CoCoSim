function [node, external_nodes_i, opens, abstractedNodes] = get__min_int(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getMinMax('min', 'int');
end