function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_3x3(lus_backend,varargin)
    % support 3x3 matrix inversion
    % 3x3 matrix inverse formulations:
    % http://mathworld.wolfram.com/MatrixInverse.html
    n = 3;
    [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n);
end