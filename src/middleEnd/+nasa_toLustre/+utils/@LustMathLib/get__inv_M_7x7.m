function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_7x7(lus_backend,varargin)
    % only KIND2 contract for 7x7 matrix inversion
    n = 7;
    [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n);
end