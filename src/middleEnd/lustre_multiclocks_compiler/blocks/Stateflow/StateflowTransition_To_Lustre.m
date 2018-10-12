classdef StateflowTransition_To_Lustre
    %StateflowTransition_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_code(transition)
            main_node = {};
            external_nodes = {};
            external_libraries = {};
            
        end
        
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %%
        %% Get unique short name
        function unique_name = getUniqueName(object, src)
            dst = object.Destination;
            id_str = sprintf('%.0f', object.Id);
            unique_name = sprintf('%s_To_%s_ID%s',...
                SLX2LusUtils.name_format(src.Name),...
                SLX2LusUtils.name_format(dst.Name), id_str );
        end
    end
    
end

