function [ ir ] = multiClocks_ir_pp( ir )
%rateTransition_ir_pp add Inport and outport compiledSampleDimension

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_path = ir.meta.file_path;
load_system(file_path);
[~, file_name, ~] = fileparts(file_path);
field_name = IRUtils.name_format(file_name);
if isfield(ir, field_name)
    Cmd = [file_name, '([], [], [], ''compile'');'];
    eval(Cmd);
    ir.(field_name) = recursiveCall(ir.(field_name));
    Cmd = [file_name, '([], [], [], ''term'');'];
    eval(Cmd);
end
end
%
function blk = recursiveCall(blk)
if isfield(blk, 'Content')
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        blk.Content.(field_names{i}) = recursiveCall(blk.Content.(field_names{i}));
    end
elseif isfield(blk, 'BlockType') ...
        && (strcmp(blk.BlockType, 'RateTransition') ...
        ||strcmp(blk.BlockType, 'ZeroOrderHold')) 
    ph = get_param(blk.Origin_path, 'PortHandles');
    blk.InportCompiledSampleTime = get_param(ph.Inport(1), 'CompiledSampleTime');
    blk.OutportCompiledSampleTime = get_param(ph.Outport(1), 'CompiledSampleTime');
end
end


