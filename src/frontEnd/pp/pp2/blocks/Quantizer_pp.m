function [status, errors_msg] = Quantizer_pp(model)
    % Quantizer_PROCESS Searches for Quantizer blocks and replaces them by a
    %  equivalent subsystem.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    errors_msg = {};

    Quantizer_list = find_system(model, ...
        'LookUnderMasks','all', 'BlockType','Quantizer');
    if not(isempty(Quantizer_list))
        display_msg('Processing Quantizer blocks...', MsgType.INFO, 'Quantizer_process', ''); 
        for i=1:length(Quantizer_list)
            try
            display_msg(Quantizer_list{i}, MsgType.INFO, 'Quantizer_process', ''); 
            QuantizationInterval = get_param(Quantizer_list{i},'QuantizationInterval' );
            replace_one_block(Quantizer_list{i},'pp_lib/quantizer');
            set_param(Quantizer_list{i}, 'LinkStatus', 'inactive');
            set_param(strcat(Quantizer_list{i},'/q'),'Value', num2str(QuantizationInterval));
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('Quantizer pre-process has failed for block %s', Quantizer_list{i});
                continue;
            end        
        end
        display_msg('Done\n\n', MsgType.INFO, 'Quantizer_process', ''); 
    end
end

