function [node, external_nodes_i, opens, abstractedNodes] = get_conv(lus_backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    opens = {'conv'};
    abstractedNodes = {};
    if ~LusBackendType.isLUSTREC(lus_backend)
        abstractedNodes = {'DataType conversion Library'};
    end
    external_nodes_i = {};
    node = '';
end