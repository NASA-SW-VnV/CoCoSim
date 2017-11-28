function  status= compile_process( new_model_base )
%compile_process check if the model can be compiled or not.

try
    status = 0;
    code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
    warning off;
    evalin('base',code_on);
    
    code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_off);
    warning on;
catch
    code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_off);
    warning on;
    status = 1;
    msg = sprintf('Make sure model "%s" can be compiled', new_model_base);
    errordlg(msg, 'CoCoSim_PP') ;
end
end

