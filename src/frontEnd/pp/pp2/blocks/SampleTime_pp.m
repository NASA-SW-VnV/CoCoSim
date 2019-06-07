function [status, errors_msg] = SampleTime_pp(new_model_base)
    %SAMPLETIME_PP Set sample time of the model so the pp model will have same
    %sample time as the original model. Sample time should be set before other
    %pre-processing calls.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    status = 0;
    errors_msg = {};
    
    try
        [st, ~] = SLXUtils.getModelCompiledSampleTime(new_model_base);
        configSet = getActiveConfigSet(new_model_base);
        if st > 0
            set_param(configSet, 'SolverType', 'Fixed-step');
            set_param(configSet, 'FixedStep', sprintf('%f', st));
        elseif st == 0
            set_param(configSet, 'SolverType', 'Fixed-step');
            set_param(configSet, 'FixedStep', '0.1');
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
        status = 1;
        errors_msg{end + 1} = sprintf('SampleTime_pp has failed. Please set your model to FixedStepDiscrete');
        return
    end
end


