function subsystems = getSubsystemsWithContract(currentModel)
    contracts = find_system(currentModel, 'LookUnderMasks', 'all',  'MaskType', 'ContractBlock');
    for i=1:numel(contracts)
        portHandles = get_param(contracts{i}, 'PortHandles');
        inportHandles = portHandles.Inport;
        srcBlockHandles = {};
        for j=1:numel(inportHandles)
            lineHandle = get_param(inportHandles(j), 'Line');
            if lineHandle ~= -1
                srcBlockHandle = get_param(lineHandle, 'SrcBlockHandle');
                srcBlockName = get_param(srcBlockHandle, 'Name');
                if ~ismember(srcBlockHandle,srcBlockHandles)
                    srcBlockHandles(end+1) = srcBlockHandle;
                end
            end
        end

        for j=1:numel(srcBlocks)                          
            srcLineHandles = get_param(srcBlockHandle, 'LineHandles');
            for k=1:numel(srcLineHandles.Outport)
                dstHandles = get_param(srcLineHandles.Outport(k), 'DstBlockHandle');
                dstNames = get_param(dstHandles, 'Name');
                if any(strcmp(dstNames, contracts{i}))

                end
            end
        end
    end
end