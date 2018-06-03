function [b, status, type, masktype, isIgnored] = getWriteType(sub_blk)
% getWriteType returns the handle of class corresponding to blockType/MaskType
% of the block in parameter.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

status = 0;
isIgnored = 0;
masktype = '';
b = [];
if ~isfield(sub_blk, 'BlockType')
    status = 1;
    return;
end
type = sub_blk.BlockType;
if Block_To_Lustre.ignored(sub_blk)
    status = 1;
    isIgnored = 1;
    return;
end

if isfield(sub_blk, 'Mask') && strcmp(sub_blk.Mask, 'on')
    masktype = sub_blk.MaskType;
    fun_name = [Block_To_Lustre.blkTypeFormat(masktype) '_To_Lustre'];
    fun_path = which(fun_name);
    if isempty(fun_path)
        type = sub_blk.BlockType;
        fun_name = [Block_To_Lustre.blkTypeFormat(type) '_To_Lustre'];
    end
else
    type = sub_blk.BlockType;
    fun_name = [Block_To_Lustre.blkTypeFormat(type) '_To_Lustre'];
end
fun_path = which(fun_name);
if isempty(fun_path)
    status = 1;
    if isempty(masktype)
        msg = sprintf('Block "%s" with BlockType "%s" is not supported', sub_blk.Origin_path, type);
    else
        msg = sprintf('Block "%s" with BlockType "%s" and MaskType "%s" is not supported', sub_blk.Origin_path, type, masktype);
    end
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