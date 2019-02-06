function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_2x2(lus_backend, varargin)
    % support 2x2 matrix inversion
    n = 2;
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.get_inverse_code(lus_backend,n);
end