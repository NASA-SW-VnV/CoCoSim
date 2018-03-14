function [] = substitute_bias_process(model)
% substitute_bias_process Searches for bias blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in

% Processing Bias blocks
Bias_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','Bias');
if not(isempty(Bias_list))
    display_msg('Replacing Bias blocks...', MsgType.INFO,...
        'Bias_process', '');
    for i=1:length(Bias_list)
        display_msg(Bias_list{i}, MsgType.INFO, ...
            'Bias_process', '');
        bias = get_param(Bias_list{i},'Bias');
        pp_name = 'bias';
        replace_one_block(Bias_list{i},fullfile('pp_lib',pp_name));
        set_param(strcat(Bias_list{i},'/bias'),...
            'Value',bias);
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'Bias_process', ''); 
end
end

