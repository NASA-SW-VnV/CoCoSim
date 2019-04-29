function [status, errors_msg] = Sin_pp(model)
    % Sin_pp Searches for Sine wave blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Processing Sine wave blocks
    status = 0;
    errors_msg = {};
    
    Sin_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','Sin');
    if not(isempty(Sin_list))
        display_msg('Replacing Sin blocks...', MsgType.INFO,...
            'Sin_pp', '');
        for i=1:length(Sin_list)
            try
                display_msg(Sin_list{i}, MsgType.INFO, ...
                    'Sin_pp', '');
                SineType = get_param(Sin_list{i},'SineType');
                TimeSource = get_param(Sin_list{i},'TimeSource');
                Amplitude = get_param(Sin_list{i},'Amplitude');
                Bias = get_param(Sin_list{i},'Bias');
                Frequency = get_param(Sin_list{i},'Frequency');
                Phase = get_param(Sin_list{i},'Phase');
                SampleTime = get_param(Sin_list{i},'SampleTime');
                
                if isequal(SineType, 'Sample based')
                    [Samples, ~, status] = SLXUtils.evalParam(...
                        model, ...
                        get_param(Sin_list{i}, 'Parent'), ...
                        Sin_list{i}, ...
                        get_param(Sin_list{i},'Samples'));
                    if status
                        errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s. Samples parameter could not be read.', Sin_list{i});
                        continue;
                    end
                    sampleTime = SLXUtils.getCompiledParam(Sin_list{i}, 'CompiledSampleTime');
                    Frequency = num2str(2*pi/(Samples* sampleTime(1)));
                    [Offset, ~, status] = SLXUtils.evalParam(...
                        model, ...
                        get_param(Sin_list{i}, 'Parent'), ...
                        Sin_list{i}, ...
                        get_param(Sin_list{i},'Offset'));
                    if status
                        errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s. Offset parameter could not be read.', Sin_list{i});
                        continue;
                    end
                    Phase = num2str(2*pi*Offset/Samples);
                end
                
                PPUtils.replace_one_block(Sin_list{i},fullfile('pp_lib', 'SineWaveFunction'));
                
                set_param(strcat(Sin_list{i},'/Freq'),...
                    'Value',Frequency);
                set_param(strcat(Sin_list{i},'/Phase'),...
                    'Value',Phase);
                set_param(strcat(Sin_list{i},'/Amp'),...
                    'Value',Amplitude);
                set_param(strcat(Sin_list{i},'/Bias'),...
                    'Value',Bias);
                
                if isequal(TimeSource, 'Use simulation time')
                    if str2num(SampleTime) == 0
                        PPUtils.replace_one_block(strcat(Sin_list{i},'/In1'),...
                            'simulink/Sources/Clock');
                    else
                        PPUtils.replace_one_block(strcat(Sin_list{i},'/In1'),...
                            'simulink/Sources/Digital Clock');
                        set_param(strcat(Sin_list{i},'/In1'),...
                            'SampleTime',SampleTime);
                    end
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s', Sin_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'Sin_pp', '');
    end
    
end

