function [failed] = replace_one_block(block,new_block)
    % REPLACE_ONE_BLOCK replaces block by the new block.
    % with the same orientation and position
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    failed = false;
    try
        Orient=get_param(block,'orientation');
        Size=get_param(block,'position');
        delete_block(block);
        add_block(new_block,block, ...
            'MakeNameUnique', 'on', ...
            'Orientation',Orient, ...
            'Position',Size);
        if MatlabUtils.startsWith(new_block, 'pp_lib/')
            set_param(block, 'LinkStatus', 'inactive');
        end
    catch
        failed = true;
    end
end

