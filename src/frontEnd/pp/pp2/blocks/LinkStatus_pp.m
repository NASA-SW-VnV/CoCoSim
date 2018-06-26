function LinkStatus_pp( new_model_base )
%LinkStatus_pp disable all libraries links. Helps changing and
%pre-processing the content of these blocks.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

all_blocks = find_system(new_model_base,'LookUnderMasks', 'all', 'FollowLinks', 'on');
if not(isempty(all_blocks))
    
    for i=1:length(all_blocks)
        try
            linkStatus = get_param(all_blocks{i},'LinkStatus');
        catch
            linkStatus = 'none';
        end
        if ~(isequal(linkStatus, 'none') || isequal(linkStatus, 'inactive'))
            display_msg(['Disable link of ' all_blocks{i}], MsgType.INFO, 'LinkStatus_pp', '');
            set_param(all_blocks{i}, 'LinkStatus', 'inactive');
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'LinkStatus_pp', '');
end

end