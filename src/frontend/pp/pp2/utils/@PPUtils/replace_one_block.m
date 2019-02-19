function [failed] = replace_one_block(block,new_block)
    % REPLACE_ONE_BLOCK replaces block by the new block.
    % with the same orientation and position
    failed = false;
    try
        Orient=get_param(block,'orientation');
        Size=get_param(block,'position');
        delete_block(block);
        add_block(new_block,block, ...
            'MakeNameUnique', 'on', ...
            'Orientation',Orient, ...
            'Position',Size);
    catch
        failed = true;
    end
end

