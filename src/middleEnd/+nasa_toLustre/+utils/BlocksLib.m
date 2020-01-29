%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
classdef BlocksLib
    %BlocksLib This class is a set of Simulink blocks as Lustre libraries.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens, abstractedNodes] = template(lus_backend)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node = '';
        end
        
    end
    
end

