%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function specInstrs_process(node_block_path, blk_spec, node_name)
    load_system(which('CoCoSimSpecification.slx'));
    assumes = blk_spec.assume;
    guarantees = blk_spec.guarantees;
    modes = blk_spec.modes;
    % add validator
    vPath = BUtils.get_unique_block_name(fullfile(node_block_path,'validator'));
    vHandle = add_block('CoCoSimSpecification/contract/validator', ...
        vPath, ...
        'MakeNameUnique', 'on', ...
        'assumePorts', num2str(length(assumes)), ...
        'guaranteePorts', num2str(length(guarantees)), ...
        'modePorts', num2str(length(modes)));

    % remove connected blocks to validator that are added by its callback
    SLXUtils.removeBlocksLinkedToMe(vHandle, false);
    % add validator output
    output_path = BUtils.get_unique_block_name(fullfile(node_block_path,'valid'));
    outHandle = add_block('simulink/Ports & Subsystems/Out1',...
        output_path);
    SrcBlkH = get_param(vHandle,'PortHandles');
    DstBlkH = get_param(outHandle, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    
    % link assumptions and guarantees and modes
    vport = 1;
    for i=1:length(assumes)
        % add assume block
        assumePath = BUtils.get_unique_block_name(fullfile(node_block_path,'assume'));
        aHandle = add_block('CoCoSimSpecification/assume', ...
            assumePath, ...
            'MakeNameUnique', 'on');
        assumePath = fullfile(node_block_path, get_param(aHandle, 'Name'));
        process_assumeGuarantee(node_block_path, assumePath, assumes(i), vHandle, vport, node_name);
        vport = vport + 1;
    end
    for i=1:length(guarantees)
        % add guarantee block
        gPath = BUtils.get_unique_block_name(fullfile(node_block_path,'guarantee'));
        gHandle = add_block('CoCoSimSpecification/guarantee', ...
            gPath, ...
            'MakeNameUnique', 'on');
        gPath = fullfile(node_block_path, get_param(gHandle, 'Name'));
        process_assumeGuarantee(node_block_path, gPath, guarantees(i), vHandle, vport, node_name);
        vport = vport + 1;
    end
    
    
    %TODO Modes
end


function process_assumeGuarantee(node_block_path, gPath, gStruct, vHandle, vPortNumber, node_name)
    % check if there is an output
    outport = find_system(gPath, 'LookUnderMasks', 'all', 'BlockType', 'Outport');
    if isempty(outport)
        outportPath = fullfile(gPath, 'Out1');
        add_block('simulink/Ports & Subsystems/Out1', outportPath);
    else
        if length(outport) > 1
            for i=2:length(outport), delete_block(outport{i});end
        end
        outportPath = outport{1};
    end
    
    % ad inport
    inport =  find_system(gPath, 'LookUnderMasks', 'all', 'BlockType', 'Inport');
    if isempty(inport)
        inportPath = fullfile(gPath, 'In1');
        add_block('simulink/Ports & Subsystems/In1', inportPath);
    else
        if length(inport) > 1
            for i=2:length(inport), delete_block(inport{i});end
        end
        inportPath = inport{1};
    end
    
    % add link
    SrcBlkH = get_param(inportPath,'PortHandles');
    DstBlkH = get_param(outportPath, 'PortHandles');
    add_line(gPath, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    
    % add outside connection
    rhs_name = BUtils.adapt_block_name(gStruct.qfexpr.value, node_name);
    rhs_path = BUtils.get_unique_block_name(strcat(gPath,'_rhs'));
    add_block('simulink/Signal Routing/From',...
        rhs_path,...
        'GotoTag',rhs_name,...
        'TagVisibility', 'local');
    SrcBlkH = get_param(rhs_path,'PortHandles');
    DstBlkH = get_param(gPath, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    
%     add link to validator block
    SrcBlkH = get_param(gPath,'PortHandles');
    DstBlkH = get_param(vHandle, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(vPortNumber), 'autorouting', 'on');
end