function [] = DigitalClock_process(model)
% DigitalClock_PROCESS Searches for DigitalClock blocks and replaces them by a
%  equivalent subsystem.
%   model is a string containing the name of the model to search in

digitalClock_list = find_system(model,'BlockType','DigitalClock');
if not(isempty(digitalClock_list))
    display_msg('Processing Clock blocks...', MsgType.INFO, 'DigitalClock_process', ''); 
    for i=1:length(digitalClock_list)
        display_msg(digitalClock_list{i}, MsgType.INFO, 'DigitalClock_process', ''); 
        digitalsampleTime = get_param(digitalClock_list{i},'SampleTime' );
        replace_one_block(digitalClock_list{i},'pp_lib/DigitalClock');
        try
            model_sample = SLXUtils.get_BlockDiagram_SampleTime(model); 
            if   model_sample==0 || isnan(model_sample) || model_sample==Inf
                model_sample = 0.2;
            end
        catch
            model_sample = 0.2;
        end
        set_param(digitalClock_list{i} ,'SystemSampleTime', num2str(model_sample));
        set_param(strcat(digitalClock_list{i},'/SampleTime'),'Value', num2str(model_sample));
        
        set_param(strcat(digitalClock_list{i},'/DigitalSample'),'Value', digitalsampleTime);
    end
    display_msg('Done\n\n', MsgType.INFO, 'DigitalClock_process', ''); 
end
end

