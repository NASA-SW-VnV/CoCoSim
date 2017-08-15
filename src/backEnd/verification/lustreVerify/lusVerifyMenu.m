function schema = lusVerifyMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Lustre compiler';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@getZustre, @getKind, @getJKind};
end


function schema = getZustre(callbackInfo)
schema = sl_action_schema;
schema.label = 'Zustre';
schema.callback = @zustreCallback;
end

function zustreCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'Z');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
% runCoCoSim;
end


function schema = getKind(callbackInfo)
schema = sl_action_schema;
schema.label = 'Kind2';
schema.callback = @kindCallback;
end

function kindCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'K');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
% runCoCoSim;
end

function schema = getJKind(callbackInfo)
schema = sl_action_schema;
schema.label = 'JKind';
schema.callback = @jkindCallback;
end

function jkindCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'J');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
% runCoCoSim;
end