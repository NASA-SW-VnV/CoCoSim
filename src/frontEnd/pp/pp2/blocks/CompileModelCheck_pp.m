function  [failed, errors_msg]= CompileModelCheck_pp( new_model_base )
%compile_process check if the model can be compiled or not.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
failed = 0;
errors_msg = {};

try
    failed = 0;
    code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
    warning off;
    evalin('base',code_on);
    
    code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_off);
    %     warning on;
catch me
    display_msg(me.getReport(), MsgType.DEBUG, 'CompileModelCheck_pp', '');
    try
        code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
        evalin('base',code_off);
    catch
    end
    failed = 1;
    msg = sprintf('Make sure model "%s" can be compiled', new_model_base);
    %errordlg(msg, 'CoCoSim_PP') ;
    errors_msg{end + 1} = msg;
end
end

