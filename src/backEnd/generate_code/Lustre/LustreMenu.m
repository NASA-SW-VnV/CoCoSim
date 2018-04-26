%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = LustreMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Lustre';
schema.callback = @LusCompilerCallback;
% schema = sl_container_schema;
% schema.label = 'Lustre';
% schema.statustip = 'Generate Lustre code';
% schema.autoDisableWhen = 'Busy';
%
% schema.childrenFcns = {@LusCompiler, @CoCoSpecCompiler};
end


function schema = LusCompiler(callbackInfo)
schema = sl_action_schema;
schema.label = 'Lustre compiler';
schema.callback = @LusCompilerCallback;
end

function LusCompilerCallback(callbackInfo)
try
    mdl_full_path = MenuUtils.get_file_name(gcs);
    ToLustre(mdl_full_path);
catch ME
    display_msg(ME.getReport(), Constants.DEBUG,'LusCompilerCallback','');
    display_msg(ME.message, Constants.ERROR,'LusCompilerCallback','');
end
end

function schema = CoCoSpecCompiler(callbackInfo)
schema = sl_action_schema;
schema.label = 'CoCoSpec compiler';
schema.callback = @CoCoSpecCompilerCallback;
end

function CoCoSpecCompilerCallback(callbackInfo)
msgbox('Not implemented yet')
end
