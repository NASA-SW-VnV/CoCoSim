function [b, status] = getWriteType(sub_blk)
% getWriteType returns the handle of class corresponding to blockType/MaskType 
% of the block in parameter.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

status = 0;
b = [];

if WriteType.NotHandled(sub_blk.BlockType)
    status = 1;
    return;
end

if strcmp(sub_blk.BlockType, 'SubSystem') && strcmp(sub_blk.Mask, 'on')
    type = sub_blk.MaskType;
    fun_name = [WriteType.blkTypeFormat(type) '_write'];
    fun_path = which(fun_name);
    if isempty(fun_path)
        type = sub_blk.BlockType;
        fun_name = [WriteType.blkTypeFormat(type) '_write'];
    end
else
    type = sub_blk.BlockType;
    fun_name = [WriteType.blkTypeFormat(type) '_write'];
end
fun_path = which(fun_name);
if isempty(fun_path)
    status = 1;
    msg = sprintf('BlockType %s not supported in %s', type, sub_blk.Origin_path);
    display_msg(msg, MsgType.ERROR, 'getWriteType', '');
    return;
else
    [parent, fname, ~] = fileparts(fun_path);
    PWD = pwd;
    if ~isempty(parent); cd(parent); end
    h = str2func(fname);
    b = h();
    if ~isempty(parent); cd(PWD); end
end

end