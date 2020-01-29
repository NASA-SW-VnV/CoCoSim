%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [node, external_nodes_i, opens, abstractedNodes] = get_simulink_math_fcn(lus_backend)
    opens = {'simulink_math_fcn'};
    abstractedNodes = {};
    if ~LusBackendType.isLUSTREC(lus_backend)
        abstractedNodes = {'simulink_math_fcn library'};
    end
    external_nodes_i = {};
    node = '';
end
