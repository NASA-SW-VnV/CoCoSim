
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% Contract header
function [node_inputs, node_outputs, ...
            node_inputs_withoutDT, node_outputs_withoutDT ] = ...
            extractContractHeader(parent_ir, contract, main_sampleTime, xml_trace)
        % This function is creating the header of the contract.
        % A contract is different from a node by having the same
        % signature of the abstracted node. So we need to divide
        % the actual Contracts inputs to inputs and outputs to
        % match the abstracted node associated to. We can also
        % allow a contract that does not take all inputs/outputs of
        % the abstracted node by extending it's signature with
        % unused inputs/outputs.
        % The order of inputs in contract in Simulink may have
        % different order from the verified SS.
        node_inputs = {};
        node_outputs = {};
        node_inputs_withoutDT = {};
        node_outputs_withoutDT = {};
        % Get the actual inputs of Contract block as a simple SS
        is_main_node = 0; isEnableORAction=0; isEnableAndTrigger=0;
        isContractBlk = 0;
        isMatlabFunction = false;
        [~, contract_inputs, contract_outputs, ...
            contract_inputs_withoutDT, contract_outputs_withoutDT ] = ...
            nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent_ir, contract, is_main_node, ...
            isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
            main_sampleTime, xml_trace);
        %change
        % get Associated SS
        if ~isfield(contract, 'AssociatedBlkHandle')
            display_msg(sprintf('Can not find AssociatedBlkHandle parameter in contract %s.', ...
                contract.Origin_path), MsgType.DEBUG, 'extractContractHeader', '');
            % keep the same contract signature
            node_inputs = contract_inputs;
            node_outputs = contract_outputs;
            node_inputs_withoutDT = contract_inputs_withoutDT;
            node_outputs_withoutDT = contract_outputs_withoutDT;
            return;
        end
        % we assume PortConnectivity is ordered by the graphical
        % order of inputs.
        associatedBlkHandle = contract.AssociatedBlkHandle;
        associatedBlk = get_struct(parent_ir, associatedBlkHandle);
        if isempty(associatedBlk)
            display_msg(sprintf('Can not find AssociatedBlkHandle parameter in contract %s.', ...
                contract.Origin_path), MsgType.DEBUG, 'extractContractHeader', '');
            % keep the same contract signature
            node_inputs = contract_inputs;
            node_outputs = contract_outputs;
            node_inputs_withoutDT = contract_inputs_withoutDT;
            node_outputs_withoutDT = contract_outputs_withoutDT;
            return;
        end
        curr_idx = 1;
        for j=1:numel(contract.PortConnectivity)
            srcBlkHandle = contract.PortConnectivity(j).SrcBlock;
            if isempty(srcBlkHandle)
                % skip "valid" output
                continue;
            end
            SrcPort = contract.PortConnectivity(j).SrcPort;
            if srcBlkHandle ~= associatedBlkHandle
                srcBlk = get_struct(parent_ir, srcBlkHandle);
                if isempty(srcBlk)
                    continue;
                end
                % input
                %get actual size after inlining.
                [names, ~] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                    parent_ir, srcBlk, SrcPort);
                for i=1:numel(names)
                    node_inputs{end + 1} = contract_inputs{curr_idx};
                    node_inputs_withoutDT{end+1} =...
                        contract_inputs_withoutDT{curr_idx};
                    curr_idx = curr_idx + 1;
                end
            else
                % output
                [names, ~] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                    parent_ir, associatedBlk, SrcPort);
                for i=1:numel(names)
                    node_outputs{end + 1} = contract_inputs{curr_idx};
                    node_outputs_withoutDT{end+1} =...
                        contract_inputs_withoutDT{curr_idx};
                    curr_idx = curr_idx + 1;
                end
            end
        end
        % add additional inputs such as simulation time and clocks
        for i=curr_idx:numel(contract_inputs)
            node_inputs{end + 1} = contract_inputs{i};
            node_inputs_withoutDT{end+1} =...
                contract_inputs_withoutDT{i};
        end

end
