function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_5x5(lus_backend,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % only KIND2 contract for 5x5 matrix inversion
    n = 5;
    [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n);
end
