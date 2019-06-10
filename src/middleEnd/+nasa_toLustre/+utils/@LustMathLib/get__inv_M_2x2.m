function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_2x2(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % support 2x2 matrix inversion
    n = 2;
    [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n);
end
