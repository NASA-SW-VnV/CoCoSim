function  [status, errors_msg] = FixedStepDiscreteSolver_pp( new_model_base )
    %ALGEBRAIC_LOOPS_PROCESS set the solver to FixedStepDiscrete.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    errors_msg = {};
    
    try
        configSet = getActiveConfigSet(new_model_base);
        set_param(configSet, 'Solver', 'FixedStepDiscrete');
        st = SLXUtils.getModelCompiledSampleTime(new_model_base);
        if st == 0
            % no discrete block in the model
            % set sample time to 0.1
            set_param(configSet, 'FixedStep', '0.1');
        end
    catch me
        display_msg(['Please set your model to FixedStepDiscrete'], MsgType.ERROR, 'PP', '');
        display_msg(me.message, MsgType.ERROR, 'PP', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
        status = 1;
        errors_msg{end + 1} = sprintf('FixedStepDiscreteSolver pre-process has failed. Please set your model to FixedStepDiscrete');
        
        return
    end
    
    
end

