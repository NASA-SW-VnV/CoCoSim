function [status, errors_msg] = ExpandNonAtomicSubsystems_pp( new_model_base )
%expand_sub_process expands all subsystems that are not atomic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

ssys_list = find_system(new_model_base,'LookUnderMasks','all', 'BlockType','SubSystem');
ssys_list_handles= get_param(ssys_list, 'Handle');
if not(isempty(ssys_list_handles))
    
    for i=1:length(ssys_list_handles)
        try
            atomic = get_param(ssys_list_handles{i},'TreatAsAtomicUnit');
            try
                mask = get_param(ssys_list_handles{i},'Mask');
            catch
                mask = 'off';
            end
            if strcmp(atomic, 'off') && ~strcmp(mask, 'on')
                display_msg(['Expanding ' ssys_list{i}], MsgType.INFO, 'ExpandNonAtomicSubsystems_pp', '');
                Simulink.BlockDiagram.expandSubsystem(ssys_list_handles{i});
            end
        catch me
            display_msg(me.message, MsgType.DEBUG, 'ExpandNonAtomicSubsystems_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('ExpandNonAtomicSubsystems pre-process has failed for block %s', ssys_list{i});
            continue;            
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end

end

