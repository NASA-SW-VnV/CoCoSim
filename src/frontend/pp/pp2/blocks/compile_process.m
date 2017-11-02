function  status= compile_process( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS raises algebric loops error.

try
    status = 0;
    code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
    warning off;
    evalin('base',code_on);
    
    code_on=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_on);
    warning on;
catch
    status = 1;
    msg = sprintf('Make sure model "%s" can be compiled', new_model_base);
    errordlg(msg, 'CoCoSim_PP') ;
end
end

