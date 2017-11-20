function  fixedStepDiscrete_process( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS set the solver to FixedStepDiscrete.
try
code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
warning off;
evalin('base',code_on);
configSet = getActiveConfigSet(new_model_base);
    set_param(configSet, 'Solver', 'FixedStepDiscrete');
code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
evalin('base',code_off);
warning on;
catch me
    display_msg(['Please set your model to FixedStepDiscrete'], MsgType.ERROR, 'PP', '');
    display_msg(me.message, MsgType.ERROR, 'PP', '');
    display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
    return
end


end

