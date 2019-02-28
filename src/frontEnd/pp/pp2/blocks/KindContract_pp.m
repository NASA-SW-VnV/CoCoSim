function [status, errors_msg] = KindContract_pp( model )
%KindContract_pp add MaskType to Kind contract blocks from old version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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