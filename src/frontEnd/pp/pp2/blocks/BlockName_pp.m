function [status, errors_msg] = BlockName_pp(model)
    % BlockName_pp Replaces all non alphabetic/numeric characters with underscore.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    errors_msg = {};
    
    % Processing all blocks
    block_list = find_system(model,'LookUnderMasks', 'all', 'FindAll', 'on', 'Regexp','on','Name','\W');
    if not(isempty(block_list))
        display_msg('Processing special characters in block names...', Constants.INFO, ...
            'BlockName_pp', '');
        for i=1:length(block_list)
            try
                path = fullfile(get_param(block_list(i), 'Parent'), get_param(block_list(i), 'Name'));
                display_msg(path, Constants.INFO, 'rename_numerical_prefix', '');
                name = get_param(block_list(i),'Name');
                %remove / before calling SLX2LusUtils.name_format
                new_name = strrep(name, '/', '_');
                set_param(block_list(i),'Name',...
                    SLX2LusUtils.name_format(new_name));
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
                status = 1;
                errors_msg{end + 1} = sprintf('BlockName pre-process has failed for block %s', path);
                continue;
            end
        end
        display_msg('Done\n\n', Constants.INFO, 'rename_numerical_prefix', '');
    end
end

