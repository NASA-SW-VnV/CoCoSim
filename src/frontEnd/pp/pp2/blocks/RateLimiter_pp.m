function [] = RateLimiter_pp(model)
% RateLimiter_pp searches for RateLimiter_pp blocks and replaces them by a
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing RateLimiter blocks
rateLimiter_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','RateLimiter');

if not(isempty(rateLimiter_list))
    display_msg('Replacing Rate Limiter blocks...', MsgType.INFO,...
        'RateLimiter_pp', '');
    
    %% pre-processing blocks
    for i=1:length(rateLimiter_list)
        display_msg(rateLimiter_list{i}, MsgType.INFO, ...
            'RateLimiter_pp', '');
        
        
        RisingSlewLimit = get_param(rateLimiter_list{i},'RisingSlewLimit' );
        FallingSlewLimit = get_param(rateLimiter_list{i},'FallingSlewLimit' );
        Init = get_param(rateLimiter_list{i},'InitialCondition');
        % replace it
        replace_one_block(rateLimiter_list{i},'pp_lib/RateLimiter');
        %restore information
        set_param(strcat(...
            rateLimiter_list{i} ,'/R'),...
            'Value', ...
            RisingSlewLimit);
        set_param(strcat(...
            rateLimiter_list{i} ,'/F'), ...
            'Value', ...
            FallingSlewLimit);
        ST = SLXUtils.getModelCompiledSampleTime(model);
        set_param(...
            strcat(rateLimiter_list{i} ,'/TS'),...
            'Value', ...
            num2str(ST));
        try
            set_param(strcat(rateLimiter_list{i},'/UD'),...
                'InitialCondition',Init);
        catch
            % the parameter is called X0 in previous verfsions of Simulink
            set_param(strcat(rateLimiter_list{i},'/UD'),...
                'X0',Init);
        end
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'RateLimiter_pp', '');
end
end




