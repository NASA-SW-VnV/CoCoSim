function [ ir ] = contract_ir_pp( ir )
%contract_ir_pp go over blocks and check if there is contract associated to
%it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_path = ir.meta.file_path;
[~, file_name, ~] = fileparts(file_path);
field_name = IRUtils.name_format(file_name);
if ~bdIsLoaded(file_name)
    load_system(file_path);
end
contract_sys_list = find_system(file_name,'LookUnderMasks', 'all',...
    'Mask', 'on', 'MaskType', 'ContractBlock');
if isempty(contract_sys_list)
    return;
end
if isfield(ir, field_name)
    ir.(field_name) = recursiveCall(ir.(field_name));
end
end
%%
function blk = recursiveCall(blk)
if isfield(blk, 'Content') && ~isempty(blk.Content)
    field_names = fieldnames(blk.Content);
    contract_names = ...
        field_names(...
        cellfun(@(x) (isfield(blk.Content.(x),'MaskType') ...
        && strcmp(blk.Content.(x).MaskType, 'ContractBlock')), field_names));
    if ~isempty(contract_names)
        % look for the subsystem attached to the contract
        contract_handles =...
            cellfun(@(x) blk.Content.(x).Handle, contract_names);
    end
    
    for i=1:numel(field_names)
        % aplly the recursiveCall on all blocks
        blk.Content.(field_names{i}) = recursiveCall(blk.Content.(field_names{i}));
        if ~isempty(contract_names) && isfield(blk.Content.(field_names{i}), 'PortConnectivity')
            
            DstBlock = [];
            for j=1:numel(blk.Content.(field_names{i}).PortConnectivity)
                DstBlock = [DstBlock,...
                    blk.Content.(field_names{i}).PortConnectivity(j).DstBlock];
            end
            contract_idx = find(ismember(contract_handles, DstBlock));
            if ~isempty(contract_idx)
                for x=contract_idx'
                    if nasa_toLustre.utils.SLX2LusUtils.isAbstractedByContract(blk.Content.(field_names{i}),...
                            blk.Content.(contract_names{x}))
                        % add contract node names to block information of the
                        % abstracted block.
                        if isfield(blk.Content.(field_names{i}), 'ContractNodeNames')
                            blk.Content.(field_names{i}).ContractNodeNames{end + 1} = ...
                               nasa_toLustre.utils.SLX2LusUtils.node_name_format(...
                                blk.Content.(contract_names{x}));
                        else
                            blk.Content.(field_names{i}).ContractNodeNames{1} = ...
                               nasa_toLustre.utils.SLX2LusUtils.node_name_format(...
                                blk.Content.(contract_names{x}));
                        end
                        if isfield(blk.Content.(field_names{i}), 'ContractHandles')
                            blk.Content.(field_names{i}).ContractHandles(end+1) = ...
                                blk.Content.(contract_names{x}).Handle;
                        else
                            blk.Content.(field_names{i}).ContractHandles(1) = ...
                                blk.Content.(contract_names{x}).Handle;
                        end
                        % add to the contract block the handle of the abstracted
                        % block
                        
                        blk.Content.(contract_names{x}).AssociatedBlkHandle = ...
                            blk.Content.(field_names{i}).Handle;
                    end
                end
            end
        end
    end
end
end
