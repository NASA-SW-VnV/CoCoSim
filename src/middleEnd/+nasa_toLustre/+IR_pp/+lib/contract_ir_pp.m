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
function [ ir ] = contract_ir_pp( ir )
    %contract_ir_pp go over blocks and check if there is contract associated to
    %it


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
