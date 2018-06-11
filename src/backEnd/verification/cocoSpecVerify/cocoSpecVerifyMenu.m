function schema = cocoSpecVerifyMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Compositional Verification';
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
assignin('base', 'SOLVER', 'K');
[ CoCoSimPreferences ] = loadCoCoSimPreferences();
CoCoSimPreferences.compositionalAnalysis = true;
PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
VerificationMenu.runCoCoSim;
end