function schema = extraOptionsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Extra options';
schema.statustip = 'Options can be helpful for developpers';
schema.autoDisableWhen = 'Busy';

options_items = extraOptions_config();

schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, options_items,...
                    'UniformOutput', false);
end
