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
    %make sure all porthandles are -1
    vPortConnectivity = get_param(vHandle, 'PortConnectivity');
    srcBlocks = {vPortConnectivity.SrcBlock};
    srcBlocks = srcBlocks(~cellfun(@isempty, srcBlocks));
    if any(cellfun(@(x) x~=-1, srcBlocks))
        % there is a connection that is not removed
    end
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
    for i=1:length(modes)
        process_mode(node_block_path, modes(i), vHandle, vport, node_name);
        vport = vport + 1;
    end
end

function process_assumeGuarantee(node_block_path, gPath, gStruct, vHandle, vPortNumber, node_name)
    % add inport outport inside
    createInportOutport(gPath);
    
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


function process_mode(node_block_path, mode, vHandle, vPortNumber, node_name)
    mode_id = mode.mode_id;
    requires = mode.require;
    ensures = mode.ensure;
    
    % add mode block
    mPath = BUtils.get_unique_block_name(fullfile(node_block_path, mode_id));
    mHandle = add_block('CoCoSimSpecification/mode', ...
        mPath, ...
        'MakeNameUnique', 'on');
    
    %add link to validator block
    SrcBlkH = get_param(mHandle,'PortHandles');
    DstBlkH = get_param(vHandle, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(vPortNumber), 'autorouting', 'on');
    
    % add require block
    rPath = BUtils.get_unique_block_name(fullfile(node_block_path, ...
        strcat(mode_id, '_require')));
    rHandle = add_block('CoCoSimSpecification/require', ...
        rPath, ...
        'MakeNameUnique', 'on');
    rPath = fullfile(node_block_path, get_param(rHandle, 'Name'));
    createInportOutport(rPath);
    %add link to mode block
    SrcBlkH = get_param(rHandle,'PortHandles');
    DstBlkH = get_param(mHandle, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    
    % add ensure block
    ePath = BUtils.get_unique_block_name(fullfile(node_block_path, ...
        strcat(mode_id, '_ensure')));
    eHandle = add_block('CoCoSimSpecification/ensure', ...
        ePath, ...
        'MakeNameUnique', 'on');
    ePath = fullfile(node_block_path, get_param(eHandle, 'Name'));
    createInportOutport(ePath);
    %add link to mode block
    SrcBlkH = get_param(eHandle,'PortHandles');
    DstBlkH = get_param(mHandle, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(2), 'autorouting', 'on');
    
    % add require conditions
    addRequireEnsureConditions(node_block_path, node_name, rPath, rHandle, requires);
    
    % add ensure conditions
    addRequireEnsureConditions(node_block_path, node_name, ePath, eHandle, ensures);
    
end
function addRequireEnsureConditions(node_block_path, node_name, rPath, rHandle, requires)
    if isempty(requires)
        % require true;
        cst_path = BUtils.get_unique_block_name(fullfile(node_block_path, ...
            strcat(rPath, '_true')));
        cHandle = add_block('simulink/Commonly Used Blocks/Constant',...
            cst_path,...
            'MakeNameUnique', 'on',...
            'Value','true',...
            'OutDataTypeStr','boolean');
        %add link to mode block
        SrcBlkH = get_param(cHandle,'PortHandles');
        DstBlkH = get_param(rHandle, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    else
        op_path = BUtils.get_unique_block_name(strcat(rPath, '_cond'));
        
        opHandle = add_block('simulink/Logic and Bit Operations/Logical Operator',...
            op_path, ...
            'MakeNameUnique', 'on',...
            'Operator', 'AND',...
            'Inputs', num2str(length(requires)));
        
        %add link to mode block
        SrcBlkH = get_param(opHandle,'PortHandles');
        DstBlkH = get_param(rHandle, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        
        %add all requires
        for i=1:length(requires)
            rhs_name = BUtils.adapt_block_name(requires(i).qfexpr.value, node_name);
            rhs_path = BUtils.get_unique_block_name(strcat(op_path,'_rhs'));
            rhsHandle = add_block('simulink/Signal Routing/From',...
                rhs_path,...
                'MakeNameUnique', 'on', ...
                'GotoTag',rhs_name,...
                'TagVisibility', 'local');
            SrcBlkH = get_param(rhsHandle,'PortHandles');
            DstBlkH = get_param(opHandle, 'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
        end
    end
end
function createInportOutport(rPath)
    % check if there is an output
    outport = find_system(rPath, 'LookUnderMasks', 'all', 'BlockType', 'Outport');
    if isempty(outport)
        outportPath = fullfile(rPath, 'Out1');
        add_block('simulink/Ports & Subsystems/Out1', outportPath);
    else
        if length(outport) > 1
            for i=2:length(outport), delete_block(outport{i});end
        end
        outportPath = outport{1};
    end
    % add inport
    inport =  find_system(rPath, 'LookUnderMasks', 'all', 'BlockType', 'Inport');
    if isempty(inport)
        inportPath = fullfile(rPath, 'In1');
        add_block('simulink/Ports & Subsystems/In1', inportPath);
    else
        if length(inport) > 1
            for i=2:length(inport), delete_block(inport{i});end
        end
        inportPath = inport{1};
    end
    % add link between inport and outport inside require
    SrcBlkH = get_param(inportPath,'PortHandles');
    DstBlkH = get_param(outportPath, 'PortHandles');
    add_line(rPath, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
