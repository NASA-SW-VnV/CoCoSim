%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% Get compiled params: CompiledPortDataTypes ...
function [res] = getCompiledParam(h, param)
    res = [];
    if iscell(h)
        slx_file_name = get_param(bdroot(h{1}), 'Name');
    else
        slx_file_name = get_param(bdroot(h), 'Name');
    end
    code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
    try
        evalin('base',code_on);
        res = get_param(h, param);
        code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
        evalin('base',code_off);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'getCompiledParam', '');
        code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
        evalin('base',code_off);
    end
end

