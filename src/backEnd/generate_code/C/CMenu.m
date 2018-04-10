%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = LustreMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'C';
schema.callback = @LusCompilerCallback;

% schema = sl_container_schema;
% schema.label = 'C';
% schema.statustip = 'Generate C code';
% schema.autoDisableWhen = 'Busy';
% 
% schema.childrenFcns = {@LusCompiler}, @SimulinkCompiler};
end


function schema = LusCompiler(callbackInfo)
schema = sl_action_schema;
schema.label = 'Lustre compiler';
schema.callback = @LusCompilerCallback;
end

function LusCompilerCallback(callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
lus_full_path = lustre_compiler(model_full_path);
output_dir = fullfile(fileparts(lus_full_path), 'C');
lustrec_C_code(lus_full_path, output_dir);
end

function schema = SimulinkCompiler(callbackInfo)
schema = sl_action_schema;
schema.label = 'Simulink Coder';
schema.callback = @SimulinkCompilerCallback;
end

function SimulinkCompilerCallback(callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
lus_full_path = lustre_compiler(model_full_path);
output_dir = fullfile(fileparts(lus_full_path), 'C');
rtwbuild_C_code(model_full_path, output_dir);

end
