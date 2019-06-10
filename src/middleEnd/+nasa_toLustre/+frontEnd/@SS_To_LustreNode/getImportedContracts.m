function imported_contracts = getImportedContracts(...
        parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT, node_outputs_withoutDT)
    %% creat import contracts body
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
                parent_ir, srcBlk, x.SrcPort);
            for i=1:numel(names)
                inputs_src_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
            end
        end
    end
    outputs_src_str = {};
    for i=1:numel(ss_ir.CompiledPortWidths.Outport)
        %get actual size after inlining.
        [names, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
            parent_ir, ss_ir, i-1);
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
                    parent_ir, srcBlk, SrcPort);
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
