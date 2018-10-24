classdef StateflowJunction_To_Lustre
    %StateflowJunction_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        
        function  [external_nodes, external_libraries ] = ...
                write_code(junction)
            external_nodes = {};
            external_libraries = {};
            T = junction.OuterTransitions;
            for i=1:numel(T)
                [transition_nodes_j, external_libraries_j ] = ...
                    StateflowTransition_To_Lustre.get_Actions(T{i}, junction, ...
                    false);
                external_nodes = [external_nodes, transition_nodes_j];
                external_libraries = [external_libraries, external_libraries_j];
            end            
            
        end
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
    end
    
end

