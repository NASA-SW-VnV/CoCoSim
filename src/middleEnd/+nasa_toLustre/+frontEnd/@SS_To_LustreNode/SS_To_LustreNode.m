classdef SS_To_LustreNode
    %SS_TO_LUSTRENODE translates a Subsystem to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
    end
    
    methods(Static)
        [ main_node, isContractBlk, external_nodes, external_libraries, abstractedBlocks ] = ...
                subsystem2node(parent_ir,  ss_ir,  main_sampleTime, ...
                is_main_node, lus_backend, coco_backend, xml_trace)        
        
        %% Go over SS Content
        [body, variables, external_nodes, external_libraries, abstractedBlocks] =...
                write_body(subsys, main_sampleTime, lus_backend, coco_backend, xml_trace)
       
        %% creat import contracts body
        imported_contracts = getImportedContracts(...
                parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT, node_outputs_withoutDT)
        %% ForIterator block
        [main_node, iterator_node] = forIteratorNode(main_node, variables,...
                node_inputs, node_outputs, contract, ss_ir)

        [new_variables, additionalOutputs, ...
                additionalInputs, inputsMemory] =...
                getForIteratorMemoryVars(variables, node_inputs, memoryIds)
        
        %% Statflow support: use old compiler from github
        [main_node, external_nodes, external_libraries] = ...
                stateflowCode(ss_ir, xml_trace)
    end
    
end

