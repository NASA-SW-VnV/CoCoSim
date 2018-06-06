function [] = TransportDelay_pp(model)
% TransportDelay_pp discretizing TransportDelay block by Delay. As we
% this pre-processing is only correct when we simulate the model with 
% fixedStep solver. 
% model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tdlyBlk_list = find_system(model,'BlockType','TransportDelay');
if not(isempty(tdlyBlk_list))
    display_msg('Processing TransportDelay blocks...', MsgType.INFO, 'TransportDelay_pp', ''); 
    main_sampleTime = SLXUtils.getModelCompiledSampleTime(model);
    for i=1:length(tdlyBlk_list)
        display_msg(tdlyBlk_list{i}, MsgType.INFO, 'TransportDelay_pp', ''); 
        % get block informations
        InitialOutput = get_param(tdlyBlk_list{i},'InitialOutput' );
        DelayTime = get_param(tdlyBlk_list{i}, 'DelayTime');
        [delayTime, status] = SLXUtils.evalParam(model, DelayTime);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                DelayTime, tdlyBlk_list{i}), ...
                MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
            continue;
        end
        % replace it
        replace_one_block(tdlyBlk_list{i},'simulink/Discrete/Delay');
        %restore information
        set_param(tdlyBlk_list{i} ,'InitialCondition', InitialOutput);
        set_param(tdlyBlk_list{i} ,'DelayLength', num2str(int32(delayTime/main_sampleTime)));
    end
    display_msg('Done\n\n', MsgType.INFO, 'TransportDelay_pp', ''); 
end
end

