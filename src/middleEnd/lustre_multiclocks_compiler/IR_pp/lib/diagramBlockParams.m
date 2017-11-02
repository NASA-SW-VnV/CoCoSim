function [ ir ] = diagramBlockParams( ir )
%DIAGRAMBLOCKPARAMS Add some parameters to the block diagram missing in the
%original IR

fields = fieldnames(ir);
file_path = ir.meta.file_path;
load_system(file_path);
[~, file_name, ~] = fileparts(file_path);
field_name = SLX2LusUtils.name_format(file_name);
if isfield(ir, field_name)
    Cmd = [file_name, '([], [], [], ''compile'');'];
    eval(Cmd);
    if ~isfield(ir.(field_name), 'Name')
        ir.(field_name).Name = file_name;
        ir.(field_name).Origin_path = file_name;
        ir.(field_name).Path = field_name;
    end
    
    if ~isfield(ir.(field_name), 'CompiledSampleTime')
        ir.(field_name).CompiledSampleTime = IRUtils.get_BlockDiagram_SampleTime(file_name);
    end 

    if ~isfield(ir.(field_name), 'Handle')
        ir.(field_name).Handle = get_param(file_name, 'Handle');
    end 
    
    Cmd = [file_name, '([], [], [], ''term'');'];
    eval(Cmd);
end


end

