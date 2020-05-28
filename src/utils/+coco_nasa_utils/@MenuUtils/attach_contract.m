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
function [status] = attach_contract(blk)
    %ATTACH_CONTRACT attach CoCoSpec Contract to the blk, encapsulate both
    %blk and contract in a masked Subsystem.
    
    %Check if the block is not a Subsyste. Contracts should be attached to subsystems.
    %Create a subsystem from block if needed.
    blkH = get_param(blk, 'Handle');
    [status, blkH]= encapsulate_block(blkH);
    if status
        errordlg('Failed to attach contract to the subsystem %s', blk)
    end
    %add a masked subsystem encapsulating the block and the contract.
    [status, maskBlk] = coco_nasa_utils.SLXUtils.createSubsystemFromBlk(blkH);
    if status
        errordlg('Failed to attach contract to the subsystem %s', blk)
    end
    add_abstraction_mask(maskBlk)
    
    
end
function add_abstraction_mask(maskBlk)
    set_param(maskBlk, 'TreatAsAtomicUnit', 'on');
    p = Simulink.Mask.create(maskBlk);
    p.set('Type', 'CoCoAbstractedSubsystem',...
        'Display', ...
        'text(0.5, 0.5, ''{\bf\fontsize{20}Abstracted Subsystem}'', ''hor'', ''center'', ''texmode'',''on'');');
    p.addParameter('Type','checkbox','Prompt','Use contract as an abstraction (the implementation will not be generated).',...
        'Name','useAbstraction');
    
end
function [status, newblk] = encapsulate_block(blkH)
    status = 0;
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
        [status, newblk] = coco_nasa_utils.SLXUtils.createSubsystemFromBlk(blkH);
    else
        newblk = blkH;
    end
    
end