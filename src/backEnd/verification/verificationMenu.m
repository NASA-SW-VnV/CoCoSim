function schema = verificationMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Verify properties using ...';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

verification_config;

schema.childrenFcns = cellfun(@Utils.funPath2Handle, verification_items,...
                    'UniformOutput', false);
end
