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
function [status, errors_msg] = ContractBlock_pp( model )
    %ContractBlock_pp if the contract is linked to non
    %Subsystem block, this funciton creates subsystem on top of it
    
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
    if ~ ( strcmp(blkType, 'SubSystem') ...
            && strcmp(mskType, '') ...
            && (strcmp(sfBlkType, '') || strcmp(sfBlkType, 'NONE')) ...
            && ~ismember('enable', portType)...
            && ~ismember('trigger', portType)...
            && ~ismember('state', portType)...
            && isempty(find_system(blkH, 'BlockType', 'ForIterator'))...
         )
        % if it is not Subsystem, we need to create a Subsystem on top of it
        %display_msg(fullfile(get_param(blkH, 'Parent'), get_param(blkH, 'Name')), MsgType.DEBUG, 'KindContract_pp', '');
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
