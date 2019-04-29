function [status, errors_msg] = ForIterator_pp( new_model_base )
%ForIterator_pp expands all subsystems that are inside ForIterator
%Subsystem. So all block memeories can be in the first level of the
%SubSystem. The translator to Lustre supports only block memories to be int
%the first level of the ForIterator subsystem.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

for_list = find_system(new_model_base,'LookUnderMasks','all', 'BlockType','ForIterator');
if not(isempty(for_list))
    
    for i=1:length(for_list)
        parent = get_param(for_list{i}, 'Parent');
        try
            ExpandNonAtomicSubsystems_pp(parent);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('ForIterator_pp pre-process has failed for block %s', parent);
            continue;            
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'ForIterator_pp', '');
end

end

