function [status, errors_msg] = ContractBlock_pp( model )
    %ContractBlock_pp if the contract is linked to non
    %Subsystem block, this funciton creates subsystem on top of it
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    errors_msg = {};
    
    contractBlocks_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','SubSystem', 'Mask', 'on', ...
        'MaskType', 'ContractBlock');
    if not(isempty(contractBlocks_list))
        display_msg('Processing Contract blocks', MsgType.INFO, 'ContractBlock_pp', '');
        
        for i=1:length(contractBlocks_list)
            try
                [blk, status] = getAssociatedBlk(contractBlocks_list{i});
                if status
                    display_msg(sprintf('Could not find associated block of %s', contractBlocks_list{i}),...
                        MsgType.ERROR, 'ContractBlock_pp', '');
                    continue;
                end
                
                ceateSubsystemFromBlk(blk);
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'ContractBlock_pp', '');
                status = 1;
                errors_msg{end + 1} = sprintf('ContractBlock pre-process has failed for block %s', contractBlocks_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'ContractBlock_pp', '');
    end
    
end

%%
function ceateSubsystemFromBlk(blkH)
    blkObj = get_param(blkH, 'Object');
    blkType = get_param(blkH, 'BlockType');
    try
        mskType = get_param(blkH, 'MaskType');
    catch
        mskType = '';
    end
    try
        sfBlkType = get_param(blkH, 'SFBlockType');
    catch
        sfBlkType = '';
    end
    portType = arrayfun(@(x) {x.Type}, blkObj.PortConnectivity);
    if ~ ( isequal(blkType, 'SubSystem') ...
            && isequal(mskType, '') ...
            && (isequal(sfBlkType, '') || isequal(sfBlkType, 'NONE')) ...
            && ~ismember('enable', portType)...
            && ~ismember('trigger', portType)...
            && ~ismember('state', portType))
        % if it is not Subsystem, we need to create a Subsystem on top of it
        display_msg(fullfile(get_param(blkH, 'Parent'), get_param(blkH, 'Name')), MsgType.DEBUG, 'KindContract_pp', '');
        SLXUtils.createSubsystemFromBlk(blkH);
    end
    
end
%%
function [blk, status] = getAssociatedBlk(contract_path)
    contractObj = get_param(contract_path, 'Object');
    blk = [];
    status = 1;
    for j=1:numel(contractObj.PortConnectivity)
        x = contractObj.PortConnectivity(j);
        if isempty(x.SrcBlock)
            continue;
        else
            if nasa_toLustre.utils.SLX2LusUtils.isAbstractedByContract(x.SrcBlock, contractObj)
                blk = x.SrcBlock;
                status = 0;
                break;
            end
        end
    end
    
end
