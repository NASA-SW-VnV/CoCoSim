function [obs_pos] = get_obs_position(parent_subsystem)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

    blocks = find_system(parent_subsystem, 'SearchDepth', '1', 'FindAll', 'on', 'Type', 'Block');
    positions = get_param(blocks, 'Position');
    max_x = 0;
    min_x = 0;
    max_y = 0;
    min_y = 0;
    for idx_pos=1:numel(positions)
        max_x = max(max_x, positions{idx_pos}(1));
        if idx_pos == 1
            min_x = positions{idx_pos}(1);
            min_y = positions{idx_pos}(2);
        else
            min_x = min(min_x, positions{idx_pos}(1));
            min_y = min(min_y, positions{idx_pos}(2));
        end
    end
    obs_pos = [max_x max_y (max_x + 150) (max_y + 60)];
end

