classdef Lus2SLXUtils
    %LUS2SLXUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)        
        %%
        node_process(new_model_name, nodes, node, node_block_path, block_pos, xml_trace)
        %%
        [x2, y2] = instrs_process(nodes, new_model_name, node_block_path, blk_exprs, node_name,  x2, y2, xml_trace)
        %%
        [x2, y2] = process_outputs(node_block_path, blk_outputs, ID, x2, y2, isBranch)
        %%
        [x2, y2] = process_inputs(node_block_path, blk_inputs, ID, x2, y2)
        %%
        [x2, y2] = process_arrow(node_block_path, blk_exprs, var, node_name, x2, y2)
        %%
        [x2, y2] = process_pre(node_block_path, blk_exprs, var, node_name, x2, y2)
        %%
         [x2, y2] = process_local_assign(node_block_path, blk_exprs, var, node_name, x2, y2)
        %%
         [x2, y2] = process_reset(node_block_path, blk_exprs, var, node_name, x2, y2)
        %%
        [x2, y2] = process_operator(node_block_path, blk_exprs, var, node_name, x2, y2)
        %%
        add_operator_block(op_path, operator, x, y2, dt)
        %%       
         [x2, y2] = process_node_call(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
        %%
        [x2, y2] = link_subsys_inputs( parent_path, subsys_block_path, inputs, var, node_name, x2, y2)
        %%    
        [x2, y2] = link_subsys_outputs( parent_path, subsys_block_path, outputs, var,node_name,  x2, y2, isBranch, branchIdx)
        %%
        [x2, y2] = process_branch(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
        %%
         [x2, y2] = process_functioncall(node_block_path, blk_exprs, var, node_name, x2, y2) 
        %%
        status = add_funLibrary_path(dst_path, fun_name, fun_library, position)
        %%
        status = AddResettableSubsystemToIfBlock(model)
        %%
        status = encapsulateWithReset(resetBlock, actionBlock)        
    end
end

