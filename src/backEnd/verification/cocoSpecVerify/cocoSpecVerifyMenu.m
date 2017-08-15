function schema = lusVerifyMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'CoCoSpec compiler';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@getKind};
end
function schema = getKind(callbackInfo)
schema = sl_action_schema;
schema.label = 'Kind2';
schema.callback = @kindCallback;
end

function kindCallback(callbackInfo)
clear;
fprintf('Kind2 on CoCoSpec compiler is in progress, come back soon!');
end