function schema = generateCodeMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Generate code';
schema.statustip = 'Generate code from Simulink';
schema.autoDisableWhen = 'Busy';

[gen_root, ~, ~] = fileparts(mfilename('fullpath'));
menu_items{1} = fullfile(gen_root, 'C', 'CMenu.m');
menu_items{2} = fullfile(gen_root, 'Lustre', 'LustreMenu.m');
menu_items{3} = fullfile(gen_root, 'Rust', 'RustMenu.m');

callbacks = cellfun(@MenuUtils.funPath2Handle, menu_items,...
    'UniformOutput', false);
schema.childrenFcns = cellfun(@(x) {@MenuUtils.addTryCatch, x}, callbacks, 'UniformOutput', false);
end
