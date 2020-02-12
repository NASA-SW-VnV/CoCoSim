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
function [b, status, type, masktype, sfblockType, isIgnored] = getWriteType(sub_blk, lus_backend)
    % getWriteType returns the handle of class corresponding to blockType/MaskType
    % of the block in parameter.
    global CoCoSimPreferences
    
    if isempty(CoCoSimPreferences)
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    end
    
    status = 0;
    isIgnored = 0;
    masktype = '';
    sfblockType = '';
    b = [];
    if ~isfield(sub_blk, 'BlockType')
        status = 1;
        return;
    end
    
    type = sub_blk.BlockType;
    if nasa_toLustre.frontEnd.Block_To_Lustre.ignored(sub_blk)
        status = 1;
        isIgnored = 1;
        return;
    end
    
    % try MaskType first
    if isfield(sub_blk, 'Mask') ...
            && strcmp(sub_blk.Mask, 'on')...
            && ~isempty(sub_blk.MaskType)
        masktype = sub_blk.MaskType;
        fun_name = [nasa_toLustre.frontEnd.Block_To_Lustre.blkTypeFormat(masktype) '_To_Lustre'];
        fun_name = sprintf('nasa_toLustre.blocks.%s', fun_name);
        try
            h = str2func(fun_name);
            b = h();
            return;
        catch
            % continue
        end
    end
    
    % try SFBlockType second
    if isfield(sub_blk, 'SFBlockType') && ~isempty(sub_blk.SFBlockType)
        sfblockType = sub_blk.SFBlockType;
        fun_name = [nasa_toLustre.frontEnd.Block_To_Lustre.blkTypeFormat(sfblockType) '_To_Lustre'];
        fun_name = sprintf('nasa_toLustre.blocks.%s', fun_name);
        try
            h = str2func(fun_name);
            b = h();
            return;
        catch
            % continue
        end
    end
    
    % Use BlockType instead
    type = sub_blk.BlockType;
    % Some blocks has blockType Subsystem but with no content.
    % They should be supported directly to Lustre
    if strcmp(type, 'SubSystem') ...
            && isempty(fieldnames(sub_blk.Content)) ...
            && ( ~isempty(sfblockType) || ~isempty(masktype))
        % continue to next cases: Abstraction
    else
        fun_name = [nasa_toLustre.frontEnd.Block_To_Lustre.blkTypeFormat(type) '_To_Lustre'];
        fun_name = sprintf('nasa_toLustre.blocks.%s', fun_name);
        try
            h = str2func(fun_name);
            b = h();
            return
        catch
            % continue
        end
    end
    
    % Check if abstraction is allowed
    if coco_nasa_utils.LusBackendType.isKIND2(lus_backend) ...
            && CoCoSimPreferences.abstract_unsupported_blocks
        try
            fun_name = 'nasa_toLustre.blocks.AbstractBlock_To_Lustre';
            h = str2func(fun_name);
            b = h();
            return
        catch
            % continue
        end
    end
    
    % The block is unsupported
    status = 1;
    if ~isempty(masktype)
        msg = sprintf('Block "%s" with BlockType "%s" and MaskType "%s" is not supported', sub_blk.Origin_path, type, masktype);
    elseif ~isempty(sfblockType)
        msg = sprintf('Block "%s" with BlockType "%s" and SFBlockType "%s" is not supported', sub_blk.Origin_path, type, sfblockType);
    else
        msg = sprintf('Block "%s" with BlockType "%s" is not supported', sub_blk.Origin_path, type);
    end
    display_msg(msg, MsgType.ERROR, 'getWriteType', '');
    return;
    
    
    
end
