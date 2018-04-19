function [] = Memory_pp(model)
% Memory_pp discretizing Memory block by UnitDelay
%   model is a string containing the name of the model to search in

memoryBlk_list = find_system(model,'BlockType','Memory');
if not(isempty(memoryBlk_list))
    display_msg('Processing Memory blocks...', MsgType.INFO, 'Memory_pp', ''); 
    for i=1:length(memoryBlk_list)
        display_msg(memoryBlk_list{i}, MsgType.INFO, 'Memory_pp', ''); 
        % get block informations
        InitialCondition = get_param(memoryBlk_list{i},'InitialCondition' );
        StateName = get_param(memoryBlk_list{i}, 'StateName');
        StateMustResolveToSignalObject = get_param(memoryBlk_list{i}, 'StateMustResolveToSignalObject');
        StateSignalObject = get_param(memoryBlk_list{i},'StateSignalObject');
        StateStorageClass = get_param(memoryBlk_list{i}, 'StateStorageClass');
        % replace it
        replace_one_block(memoryBlk_list{i},'simulink/Discrete/Unit Delay');
        %restore information
        set_param(memoryBlk_list{i} ,'InitialCondition', InitialCondition);
        set_param(memoryBlk_list{i} ,'StateName', StateName);
        set_param(memoryBlk_list{i} ,'StateMustResolveToSignalObject', StateMustResolveToSignalObject);
        set_param(memoryBlk_list{i} ,'StateSignalObject', StateSignalObject);
        set_param(memoryBlk_list{i} ,'StateStorageClass', StateStorageClass);
    end
    display_msg('Done\n\n', MsgType.INFO, 'Memory_pp', ''); 
end
end

