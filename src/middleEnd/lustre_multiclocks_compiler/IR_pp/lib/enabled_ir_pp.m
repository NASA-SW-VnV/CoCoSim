function [ ir ] = enabled_ir_pp( ir_in )
%enabled_ir_pp Add a parameter to all blocks that indicates if the block
%can be disabled by an enabled port.
ir = ir_in;
file_path = ir.meta.file_path;
load_system(file_path);
[~, file_name, ~] = fileparts(file_path);
diagram = SLX2LusUtils.name_format(file_name);
ir.(diagram) = recursiveCall(ir.(diagram));

end

function [ir] = recursiveCall(ir_in)
ir = ir_in;
if isfield(ir, 'Content')
    enable_Ports = find_system(ir.Origin_path, 'searchdepth', 1, 'BlockType', 'EnablePort');
    if isempty(enable_Ports)
        ir.isEnabled = 0;
        field_names = fieldnames(ir.Content);
        for i=1:numel(field_names)
            ir.Content.(field_names{i}) = recursiveCall(ir.Content.(field_names{i}));
        end
    else
        ir = makeAsEnable(ir);
    end
else
    ir.isEnabled = 0;
end
end

function ir = makeAsEnable(ir_in)
ir = ir_in;
ir.isEnabled = 1;
if isfield(ir, 'Content')
    field_names = fieldnames(ir.Content);
    for i=1:numel(field_names)
        ir.Content.(field_names{i}) = makeAsEnable(ir.Content.(field_names{i}));
    end
end
end