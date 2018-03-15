function [] = substitute_dotproduct_process(model)
% substitute_product_process Searches for DotProduct blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in

% Processing DotProduct blocks
DotProduct_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','DotProduct');
if not(isempty(DotProduct_list))
    display_msg('Replacing DotProduct blocks...', MsgType.INFO,...
        'DotProduct_process', '');
    for i=1:length(DotProduct_list)
        display_msg(DotProduct_list{i}, MsgType.INFO, ...
            'DotProduct_process', '');
        %DotProduct = get_param(DotProduct_list{i},'DotProduct');
        pp_name = 'DotProduct';
        outputDataType = get_param(DotProduct_list{i}, 'OutDataTypeStr');
        RndMeth = get_param(DotProduct_list{i}, 'RndMeth');
        OutMin = get_param(DotProduct_list{i}, 'OutMin');
        OutMax = get_param(DotProduct_list{i}, 'OutMax');
        InputSameDT = get_param(DotProduct_list{i}, 'InputSameDT');
        SaturateOnIntegerOverflow = get_param(DotProduct_list{i}, 'SaturateOnIntegerOverflow');
        LockScale = get_param(DotProduct_list{i}, 'LockScale');
        
        replace_one_block(DotProduct_list{i},fullfile('pp_lib',pp_name));

        set_param(strcat(DotProduct_list{i},'/Product'),...
            'OutDataTypeStr',outputDataType);
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'RndMeth',RndMeth);             
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'OutMin',OutMin);
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'OutMax',OutMax);          
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'InputSameDT',InputSameDT);
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);          
        set_param(strcat(DotProduct_list{i},'/Product'),...
            'LockScale',LockScale);       
        
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'DotProduct_process', ''); 
end
end

