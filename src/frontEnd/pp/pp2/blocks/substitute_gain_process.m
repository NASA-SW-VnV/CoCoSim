function [] = substitute_gain_process(model)
% substitute_gain_process Searches for gain blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in

% Processing Gain blocks
Gain_list = find_system(model,'BlockType','Gain');
if not(isempty(Gain_list))
    display_msg('Processing Gain blocks...', MsgType.INFO,...
        'Gain_process', '');
    for i=1:length(Gain_list)
        display_msg(Gain_list{i}, MsgType.INFO, ...
            'Gain_process', '');
        gain = get_param(Gain_list{i},'Gain');
        outputDataType = get_param(Gain_list{i}, 'OutDataTypeStr');
        Multiplication = get_param(Gain_list{i}, 'Multiplication');
        if strcmp(Multiplication, 'Element-wise(K.*u)')
            pp_name = 'gain_ElementWise';
        elseif strcmp(Multiplication, 'Matrix(K*u)') ...
                || strcmp(Multiplication, 'Matrix(K*u) (u vector)')
            pp_name = 'gain_K_U';
        elseif strcmp(Multiplication, 'Matrix(u*K)')
            pp_name = 'gain_U_K';
        end
        replace_one_block(Gain_list{i},fullfile('pp_lib',pp_name));
        set_param(strcat(Gain_list{i},'/K'),...
            'Value',gain);
        if strcmp(outputDataType, 'Inherit: Same as input')
            outputDataType = 'Inherit: Same as first input';
        end
        set_param(strcat(Gain_list{i},'/Product'),...
            'OutDataTypeStr',outputDataType);

    end
    display_msg('Done\n\n', MsgType.INFO, 'Gain_process', ''); 
end
end

