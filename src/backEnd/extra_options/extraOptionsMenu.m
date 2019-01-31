function schema = extraOptionsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Extra options';
schema.statustip = 'Options can be helpful for developpers';
schema.autoDisableWhen = 'Busy';

[validation_root, ~, ~] = fileparts(mfilename('fullpath'));
options_items{1} = fullfile(validation_root, 'pp', 'ppMenu.m');
options_items{2} = fullfile(validation_root, 'IR', 'IRMenu.m');
options_items{3} = fullfile(validation_root, 'contractToSLDV', 'contractToSLDVMenu.m');
options_items{4} = fullfile(validation_root, 'validation','validationMenu.m');

callbacks = cellfun(@MenuUtils.funPath2Handle, options_items,...
    'UniformOutput', false);
schema.childrenFcns = cellfun(@(x) {@MenuUtils.addTryCatch, x}, callbacks, 'UniformOutput', false);
end
