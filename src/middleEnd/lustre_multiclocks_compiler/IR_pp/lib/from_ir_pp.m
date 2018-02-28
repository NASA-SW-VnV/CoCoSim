function [ ir ] = from_ir_pp( ir_in )
%from_ir_pp Add a parameter to From block that refers to the ascociate Goto
%block handle.
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
    field_names = fieldnames(ir.Content);
    for i=1:numel(field_names)
        ir.Content.(field_names{i}) = recursiveCall(ir.Content.(field_names{i}));
    end
elseif isfield(ir, 'BlockType') && strcmp(ir.BlockType ,'From')
    % add GotoPairhandle
    parent = fileparts(ir.Origin_path);
    goToPath = find_system(parent,'SearchDepth',1,...
        'BlockType','Goto','GotoTag',ir.GotoTag);
    if ~isempty(goToPath)
        ir.GotoPair = get_param(goToPath{1}, 'Handle');
    end
end
end