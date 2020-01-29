%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
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
        specInstrs_process(node_block_path, blk_spec, node_name)
        %%
        hasMemory = instr_mayHaveMemory(instr)
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
        %%
        [dt, dim] = getArgDataType(arg)
        
    end
end

