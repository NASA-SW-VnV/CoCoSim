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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imported_contracts = getImportedContracts(...
        parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT, node_outputs_withoutDT)
    %% creat import contracts body

    
    %
    %
    % contracts may have differents signature of the node imported
    % in. This function is trying to make the use of contract the most
    % flexible possible. For example having only specific inputs
    % and outputs of the node.
    imported_contracts = {};
    % creating the inputs srcBlk_srcPort information to map it
    % later
    inputs_src_str = {};
    for j=1:numel(ss_ir.PortConnectivity)
        x = ss_ir.PortConnectivity(j);
        if isempty(x.SrcBlock)
            continue;
        else
            srcBlk = get_struct(parent_ir, x.SrcBlock);
            if isempty(srcBlk)
                continue;
            end
            %get actual size after inlining.
            [names, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                parent_ir, srcBlk, x.SrcPort, [], main_sampleTime);
            for i=1:numel(names)
                inputs_src_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
            end
        end
    end
    outputs_src_str = {};
    for i=1:numel(ss_ir.CompiledPortWidths.Outport)
        %get actual size after inlining.
        [names, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
            parent_ir, ss_ir, i-1, [], main_sampleTime);
        for j=1:numel(names)
            outputs_src_str{end+1} = sprintf('%.5f_%d', ss_ir.Handle, i-1);
        end
    end
    for i=1:numel(ss_ir.ContractHandles)
        contract_inputs = {};
        contract_outputs = {};
        contract_handle = ss_ir.ContractHandles(i);
        contractBlk = get_struct(parent_ir, contract_handle);
        if isempty(contractBlk)
            continue;
        end
        for j=1:numel(contractBlk.PortConnectivity)
            srcBlkHandle = contractBlk.PortConnectivity(j).SrcBlock;
            if isempty(srcBlkHandle)
                % skip "valid" output
                continue;
            end
            srcBlk = get_struct(parent_ir, srcBlkHandle);
            if isempty(srcBlk)
                continue;
            end
            SrcPort = contractBlk.PortConnectivity(j).SrcPort;
            srcPortHandleStr =  sprintf('%.5f_%d', srcBlkHandle, SrcPort);
            I = find(strcmp(srcPortHandleStr, inputs_src_str));
            if ~isempty(I)
                % we may have inputs from the same blk.
                %get actual size after inlining.
                [names, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                    parent_ir, srcBlk, SrcPort, [], main_sampleTime);
                I = I(1:numel(names));
                contract_inputs = [contract_inputs,...
                    node_inputs_withoutDT(I)];
                continue;
            end
            I = find(strcmp(srcPortHandleStr, outputs_src_str));
            if ~isempty(I)
                contract_outputs = [contract_outputs,...
                    node_outputs_withoutDT(I)];
                continue;
            end
            % case of Action inputs are ignored for the moment.
        end
        [~, contract_inputs] = ...
           nasa_toLustre.utils.SLX2LusUtils.getTimeClocksInputs(ss_ir, main_sampleTime, {}, contract_inputs);
        imported_contracts{end+1} = nasa_toLustre.lustreAst.ContractImportExpr(...
            ss_ir.ContractNodeNames{i}, contract_inputs, contract_outputs);
    end
end
