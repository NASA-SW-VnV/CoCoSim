function schema = generateCodeMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Generate code';
schema.statustip = 'Generate code from Simulink';
schema.autoDisableWhen = 'Busy';

generateCode_config;
schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, menu_items,...
    'UniformOutput', false);
end
