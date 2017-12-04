function schema = validationMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Validate compiler';
schema.statustip = 'Validate the translation using one of the validations process';
schema.autoDisableWhen = 'Busy';

validation_items = validation_config();

schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, validation_items,...
                    'UniformOutput', false);
end
