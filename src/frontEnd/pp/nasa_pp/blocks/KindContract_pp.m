%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
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
%function [status, errors_msg] = KindContract_pp( model )
%KindContract_pp add MaskType to Kind contract blocks from old version.

% Configure any subsystem to be treated as Atomic
status = 0;
errors_msg = {};

masked_sys_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','SubSystem', 'Mask', 'on');
masked_sys_list = [masked_sys_list;...
    find_system(model,'FollowLinks', 'on', ...
    'LookUnderMasks', 'all', 'BlockType','M-S-Function', 'Mask', 'on')];
    
% take only contract blocks
contractBlocks_list = masked_sys_list(cellfun(@(x) ismember('ContractBlockType', get_param(x, 'MaskNames')), masked_sys_list));
if not(isempty(contractBlocks_list))
    display_msg('Processing Contract blocks', MsgType.INFO, 'PP', '');
    
    for i=1:length(contractBlocks_list)
        try
        % setting the MaskType
        try
            if isempty(get_param(contractBlocks_list{i},'MaskType'))
                set_param(contractBlocks_list{i},'MaskType',...
                    get_param(contractBlocks_list{i}, 'ContractBlockType'));
            end
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'KindContract_pp', '');
        end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('contractBlocks pre-process has failed for block %s', contractBlocks_list{i});
            continue;
        end        
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end

% take only LustreOperator blocks
LusOperator_list = masked_sys_list(cellfun(@(x) ismember('LustreOperatorBlock', get_param(x, 'MaskNames')), masked_sys_list));
if not(isempty(LusOperator_list))
    display_msg('Processing LustreOperator blocks', MsgType.INFO, 'PP', '');
    
    for i=1:length(LusOperator_list)
        % setting the MaskType
        try
            set_param(LusOperator_list{i},'MaskType',...
                get_param(LusOperator_list{i}, 'LustreOperatorBlock'));
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'KindContract_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('LusOperator pre-process has failed for block %s', LusOperator_list{i});
            continue;            
        end
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end
end