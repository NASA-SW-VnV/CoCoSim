function  compile_process( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS raises algebric loops error.

try
    code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
    warning off;
    evalin('base',code_on);
    
    code_on=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_on);
    warning on;
catch
    warndlg('Make sure your model can be compiled') ;
end
end

