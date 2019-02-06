function [node, external_nodes_i, opens, abstractedNodes] = get__max_int(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getMinMax('max', 'int');
end