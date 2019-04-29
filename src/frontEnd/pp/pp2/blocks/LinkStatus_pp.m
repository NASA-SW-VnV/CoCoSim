function [status, errors_msg] = LinkStatus_pp( new_model_base )
%LinkStatus_pp disable all libraries links. Helps changing and
%pre-processing the content of these blocks.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

all_blocks = find_system(new_model_base,'LookUnderMasks', 'all',...
    'FollowLinks', 'on', 'LinkStatus', 'resolved' );
all_blocks = [all_blocks; ...
    find_system(new_model_base,'LookUnderMasks', 'all',...
    'FollowLinks', 'on', 'LinkStatus', 'unresolved' )];
if not(isempty(all_blocks))
    
    for i=1:length(all_blocks)
        try
            try
                linkStatus = get_param(all_blocks{i},'LinkStatus');
            catch
                linkStatus = 'none';
            end
            if ~(strcmp(linkStatus, 'none') || strcmp(linkStatus, 'inactive'))
                display_msg(['Disable link of ' all_blocks{i}], MsgType.INFO, 'LinkStatus_pp', '');
                set_param(all_blocks{i}, 'LinkStatus', 'inactive');
            end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('LinkStatus pre-process has failed for block %s', all_blocks{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'LinkStatus_pp', '');
end

end