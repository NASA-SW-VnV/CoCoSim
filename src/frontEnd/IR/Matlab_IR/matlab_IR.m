function [ fun_ir_path, status ] = matlab_IR( fun_path, dst_path )
%matlab_IR exports an internal presentation of matlab function givin in
%parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

em_jar_path = which('Matlab-Parser.jar');

if isempty(em_jar_path)
    display_msg('EM.jar not found.', MsgType.ERROR, 'matlab_IR', '');
    status = 1;
    return;
end
[fun_dir, fun_name, ~] = fileparts(fun_path);
if nargin == 2 && ~isempty(dst_path)
    fun_ir_path = fullfile(dst_path, strcat(fun_name, '.json'));
else
    fun_ir_path = fullfile(fun_dir, strcat(fun_name, '.json'));
end

em2json =  cocosim.matlab2IR.EM2JSON;
try
    em2json.MFileToIR(fun_path, fun_ir_path);
catch
    msg = sprintf('Could not generate Matlab IR for %s', fun_path);
    display_msg(msg, MsgType.ERROR, 'matlab_IR', '');
    return;
end

if exist(fun_ir_path, 'file')
    msg = sprintf('MATLAB IR for function %s is in %s', fun_name, fun_ir_path);
    display_msg(msg, MsgType.INFO, 'matlab_IR', '');
    status = 0;
else
    msg = sprintf('Could not generate Matlab IR for %s', fun_path);
    display_msg(msg, MsgType.ERROR, 'matlab_IR', '');
    status = 1;
end
end

