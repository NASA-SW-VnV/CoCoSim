classdef MCDC2SLX
%MCDC2SLX translate MC-DC conditions in EMF json file to Simulink blocks.
%Every node is translated to a subsystem. If OnlyMainNode is true than only
%the main node specified
%in main_node argument will be kept in the final simulink model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
    end
    
    methods(Static)
        [status, new_model_path, mcdc_trace] = ...
            transform(json_path, mdl_trace, output_dir, new_model_name, ...
            main_node, organize_blocks)

        %%
        mcdc_node_process(new_model_name, nodes, node, ...
                node_block_path, mdlTraceRoot, block_pos, xml_trace)

        %%
        variables_names = mcdcVariables(node_struct)

        %%
        [instructionsIDs, inputList]= get_mcdc_instructions(initial_variables_names, ...
                lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables)

        %%
        [x2, y2] = process_mcdc_outputs(node_block_path, blk_outputs, ID, x2, y2)

    end
end