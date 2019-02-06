function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_4x4(lus_backend,varargin)
    % support 4x4 matrix inversion
    % http://semath.info/src/inverse-cofactor-ex4.html
    n = 4;
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.get_inverse_code(lus_backend,n);
end