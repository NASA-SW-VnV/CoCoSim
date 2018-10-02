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
if not(isempty(ssys_list))
    
    for i=1:length(ssys_list)
        try
            atomic = get_param(ssys_list{i},'TreatAsAtomicUnit');
            if strcmp(atomic, 'off')
                display_msg(['Expanding ' ssys_list{i}], MsgType.INFO, 'PP', '');
                Simulink.BlockDiagram.expandSubsystem(ssys_list{i});
            end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('ExpandNonAtomicSubsystems pre-process has failed for block %s', ssys_list{i});
            continue;            
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end

end

