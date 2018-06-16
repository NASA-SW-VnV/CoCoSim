function [] = RateLimiter_pp(model)
% RateLimiter_pp searches for RateLimiter_pp blocks and replaces them by a
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing RateLimiter blocks
rateLimiter_list = find_system(model,'FollowLinks', 'on', ...
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
        
        % replace it
        replace_one_block(rateLimiter_list{i},'pp_lib/RateLimiter');
        %restore information
        set_param(rateLimiter_list{i} ,'/UB', RisingSlewLimit);
        set_param(rateLimiter_list{i} ,'/LB', FallingSlewLimit);
        ST = SLXUtils.getModelCompiledSampleTime(model);
        set_param(rateLimiter_list{i} ,'/TS', ST);
        set_param(rateLimiter_list{i} ,'/R', RisingSlewLimit);
        set_param(rateLimiter_list{i} ,'/F', FallingSlewLimit);
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'RateLimiter_pp', '');
end
end




