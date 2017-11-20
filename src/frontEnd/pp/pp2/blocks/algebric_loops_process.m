function err = algebric_loops_process( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS raises algebric loops error.

code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
warning off;
evalin('base',code_on);
loops = Simulink.BlockDiagram.getAlgebraicLoops(bdroot);

code_on=sprintf('%s([], [], [], ''term'')', new_model_base);
evalin('base',code_on);
if numel(loops) > 0
    err = 1;
    errordlg('Please fix these algebric loops (maybe by adding unit Delays)', 'CocoSim')
    return;
end
warning on;
end

