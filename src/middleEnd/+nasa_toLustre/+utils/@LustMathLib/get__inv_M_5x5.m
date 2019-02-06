function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_5x5(lus_backend,varargin)
    % only KIND2 contract for 5x5 matrix inversion
    n = 5;
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.get_inverse_code(lus_backend,n);
end