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
end


function LusCompilerCallback(callbackInfo)
try
    mdl_full_path = MenuUtils.get_file_name(gcs);
    CoCoSimPreferences = load_coco_preferences();
    if CoCoSimPreferences.lustreCompiler == 1
        ToLustre(mdl_full_path);
    elseif CoCoSimPreferences.lustreCompiler == 2
        cocoSpecCompiler(mdl_full_path);
    else
        lustre_compiler(mdl_full_path);
    end
catch ME
    display_msg(ME.getReport(), Constants.DEBUG,'LusCompilerCallback','');
    display_msg(ME.message, Constants.ERROR,'LusCompilerCallback','');
end
end

