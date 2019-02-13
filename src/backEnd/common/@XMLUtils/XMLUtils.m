classdef XMLUtils
    %XMLUtils Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    properties
    end
    
    methods (Static = true)
        
        
        %%
        %this help to get the name of Simulink block from lustre
        %variable name, using the generated tracability by Cocosim.
        [block_name, out_port_nb, dimension] = get_block_name_from_variable_using_xRoot(xRoot, node_name, var_name)
        %%
        simulink_block_name =...
                get_Simulink_block_from_lustre_node_name(...
                traceability, ...
                lustre_node_name, ...
                Sim_file_name,...
                new_model_name)

        %%
        node_name = get_lustre_node_from_Simulink_block_name(trace_file,Simulink_block_name)

        % get variables +inputs + outputs names of a node
        variables_names = get_tracable_variables(xRoot, node_name)

    end
end

