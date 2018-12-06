function schema = extraOptionsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Extra options';
schema.statustip = 'Options can be helpful for developpers';
schema.autoDisableWhen = 'Busy';

[validation_root, ~, ~] = fileparts(mfilename('fullpath'));
options_items{1} = fullfile(validation_root, 'pp', 'ppMenu.m');
options_items{2} = fullfile(validation_root, 'IR', 'IRMenu.m');
options_items{3} = fullfile(validation_root, 'contractToSLDV', 'contractToSLDVMenu.m');

schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, options_items,...
    'UniformOutput', false);
end
