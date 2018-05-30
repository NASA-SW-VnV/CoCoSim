function [ ir ] = rateTransition_ir_pp( ir )
%rateTransition_ir_pp add Inport and outport compiledSampleDimension

file_path = ir.meta.file_path;
load_system(file_path);
[~, file_name, ~] = fileparts(file_path);
field_name = SLX2LusUtils.name_format(file_name);
if isfield(ir, field_name)
    Cmd = [file_name, '([], [], [], ''compile'');'];
    eval(Cmd);
    ir.(field_name) = recursiveGeneration(ir.(field_name));
    Cmd = [file_name, '([], [], [], ''term'');'];
    eval(Cmd);
end
end
%
function blk = recursiveGeneration(blk)
if isfield(blk, 'Content')
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        blk.Content.(field_names{i}) = recursiveGeneration(blk.Content.(field_names{i}));
    end
elseif isfield(blk, 'BlockType') && strcmp(blk.BlockType, 'RateTransition')
    ph = get_param(blk.Origin_path, 'PortHandles');
    blk.InportCompiledSampleTime = get_param(ph.Inport(1), 'CompiledSampleTime');
    blk.OutportCompiledSampleTime = get_param(ph.Outport(1), 'CompiledSampleTime');
end
end


