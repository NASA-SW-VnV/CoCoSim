function [node, external_nodes_i, opens, abstractedNodes] = get__max_real(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getMinMax('max', 'real');
end