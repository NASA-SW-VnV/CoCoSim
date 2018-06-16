function KindContract_pp( model )
%KindContract_pp add MaskType to Kind contract blocks from old version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configure any subsystem to be treated as Atomic
masked_sys_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','SubSystem', 'Mask', 'on');
%add validator to the list
masked_sys_list = [masked_sys_list;...
    find_system(model,'LookUnderMasks', 'all', 'BlockType','M-S-Function', 'Mask', 'on')];
    
% take only contract blocks
masked_sys_list = masked_sys_list(cellfun(@(x) ismember('ContractBlockType', get_param(x, 'MaskNames')), masked_sys_list));
if not(isempty(masked_sys_list))
    display_msg('Processing Contract blocks', MsgType.INFO, 'PP', '');
    
    for i=1:length(masked_sys_list)
        display_msg(masked_sys_list{i}, MsgType.DEBUG, 'KindContract_pp', '');
        % setting the MaskType
        try
            set_param(masked_sys_list{i},'MaskType',...
                get_param(masked_sys_list{i}, 'ContractBlockType'));
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'KindContract_pp', '');
        end
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end
end