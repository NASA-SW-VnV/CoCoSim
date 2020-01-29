function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_6x6(lus_backend,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    % only KIND2 contract for 6x6 matrix inversion
    n = 6;
    [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n);
end
