function schema = generateInvariantsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'View generated CoCoSpec (Experimental)';
schema.statustip = 'Generate the invariants used for safe properties';
schema.autoDisableWhen = 'Busy';

generateInvariants_config;
schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, menu_items,...
                    'UniformOutput', false);
end
