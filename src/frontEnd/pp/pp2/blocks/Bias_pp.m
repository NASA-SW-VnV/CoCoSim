function [] = Bias_pp(model)
% substitute_bias_process Searches for bias blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Bias blocks
Bias_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','Bias');
if not(isempty(Bias_list))
    display_msg('Replacing Bias blocks...', MsgType.INFO,...
        'Bias_process', '');
    for i=1:length(Bias_list)
        display_msg(Bias_list{i}, MsgType.INFO, ...
            'Bias_process', '');
        bias = get_param(Bias_list{i},'Bias');
        SaturateOnIntegerOverflow = get_param(Bias_list{i},'SaturateOnIntegerOverflow');
        pp_name = 'bias';
        replace_one_block(Bias_list{i},fullfile('pp_lib',pp_name));
        set_param(strcat(Bias_list{i},'/bias'),...
            'Value',bias);
        set_param(strcat(Bias_list{i},'/Sum'),...
            'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'Bias_process', ''); 
end
end

