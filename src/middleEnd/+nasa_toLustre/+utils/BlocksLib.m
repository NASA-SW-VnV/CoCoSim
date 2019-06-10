%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
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

