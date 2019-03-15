function [status, errors_msg] = Relay_pp(model)
    % Relay_PROCESS Searches for Relay blocks and replaces them by a
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

    Relay_list = find_system(model,...
        'LookUnderMasks','all', 'BlockType','Relay');
    if not(isempty(Relay_list))
        display_msg('Processing Relay blocks...', MsgType.INFO, 'Relay_process', ''); 
        for i=1:length(Relay_list)
            try
            display_msg(Relay_list{i}, MsgType.INFO, 'Relay_process', ''); 
            OnSwitchValue = get_param(Relay_list{i},'OnSwitchValue' );
            OffSwitchValue = get_param(Relay_list{i},'OffSwitchValue' );
            OnOutputValue = get_param(Relay_list{i},'OnOutputValue' );
            OffOutputValue = get_param(Relay_list{i},'OffOutputValue' );
            OutMin = get_param(Relay_list{i},'OutMin' );
            OutMax = get_param(Relay_list{i},'OutMax' );
            %check for Enumeration
            outputDT = get_param(Relay_list{i},'OutDataTypeStr' );
            isEnum = false;
            if MatlabUtils.startsWith(outputDT, 'Enum:')
                isEnum = true;
                InitialOutput = OffOutputValue;
            end
            % replace
            PPUtils.replace_one_block(Relay_list{i},'pp_lib/relay');
            set_param(strcat(Relay_list{i},'/OnSwitchValue'),'Value', OnSwitchValue);
            set_param(strcat(Relay_list{i},'/OffSwitchValue'),'Value', OffSwitchValue);
            set_param(strcat(Relay_list{i},'/OnOutputValue'),'Value', OnOutputValue);
            set_param(strcat(Relay_list{i},'/OffOutputValue'),'Value', OffOutputValue);
            set_param(strcat(Relay_list{i},'/Out1'),'OutMin', OutMin);
            set_param(strcat(Relay_list{i},'/Out1'),'OutMax', OutMax);
            if isEnum
                try
                    set_param(strcat(Relay_list{i},'/Unit Delay'),'InitialCondition', InitialOutput);
                catch
                end
            end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('Relay pre-process has failed for block %s', Relay_list{i});
                continue;
            end        
        end
        display_msg('Done\n\n', MsgType.INFO, 'Relay_process', ''); 
    end
end

