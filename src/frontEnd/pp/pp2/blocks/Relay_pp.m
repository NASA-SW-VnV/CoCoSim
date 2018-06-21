function [] = Relay_pp(model)
% Relay_PROCESS Searches for Relay blocks and replaces them by a
%  equivalent subsystem.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Relay_list = find_system(model,...
    'LookUnderMasks','all', 'BlockType','Relay');
if not(isempty(Relay_list))
    display_msg('Processing Relay blocks...', MsgType.INFO, 'Relay_process', ''); 
    for i=1:length(Relay_list)
        display_msg(Relay_list{i}, MsgType.INFO, 'Relay_process', ''); 
        OnSwitchValue = get_param(Relay_list{i},'OnSwitchValue' );
        OffSwitchValue = get_param(Relay_list{i},'OffSwitchValue' );
        OnOutputValue = get_param(Relay_list{i},'OnOutputValue' );
        OffOutputValue = get_param(Relay_list{i},'OffOutputValue' );
        
        replace_one_block(Relay_list{i},'pp_lib/relay');
        set_param(strcat(Relay_list{i},'/OnSwitchValue'),'Value', OnSwitchValue);
        set_param(strcat(Relay_list{i},'/OffSwitchValue'),'Value', OffSwitchValue);
        set_param(strcat(Relay_list{i},'/OnOutputValue'),'Value', OnOutputValue);
        set_param(strcat(Relay_list{i},'/OffOutputValue'),'Value', OffOutputValue);
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'Relay_process', ''); 
end
end

