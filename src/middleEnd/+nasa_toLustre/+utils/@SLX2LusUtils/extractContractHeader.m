
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
