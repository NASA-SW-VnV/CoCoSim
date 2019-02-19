function [status, errors_msg] = WithinImplies_pp(model)
    % WithinImplies_pp Searches for WithinImplies blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Processing Gain blocks
    status = 0;
    errors_msg = {};

    wimplies_list = find_system(model, ...
        'LookUnderMasks', 'all', 'MaskType','Within Implies');
    if not(isempty(wimplies_list))
        display_msg('Replacing Within Implies blocks...', MsgType.INFO,...
            'WithinImplies_pp', '');
        for i=1:length(wimplies_list)
            try
                display_msg(wimplies_list{i}, MsgType.INFO, ...
                    'WithinImplies_pp', '');
                reset = get_param(wimplies_list{i},'reset');
                if isequal(reset, 'off')
                    pp_name = 'WithinImpliesResetFalse';
                else
                    pp_name = 'WithinImpliesResetTrue';
                end
                PPUtils.replace_one_block(wimplies_list{i},fullfile('pp_lib',pp_name));
                set_param(wimplies_list{i}, 'LinkStatus', 'inactive');
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('WithinImplies pre-process has failed for block %s', wimplies_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'WithinImplies_pp', '');
    end

end

