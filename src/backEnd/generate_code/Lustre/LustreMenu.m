%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = LustreMenu(~)
schema = sl_container_schema;
schema.label = 'Lustre';
schema.statustip = 'Generate Lustre Code';
schema.autoDisableWhen = 'Busy';
schema.childrenFcns = {@getKind, @getLustrec};
end

function schema = getKind(varargin)
schema = sl_action_schema;
schema.label = 'Kind2';
schema.callback =  @(x) LusCompilerCallback(BackendType.KIND2, x);
end

function schema = getLustrec(varargin)
schema = sl_action_schema;
schema.label = 'LustreC';
schema.callback =  @(x) LusCompilerCallback(BackendType.LUSTREC, x);
end

function LusCompilerCallback(bckend, ~)
try
    mdl_full_path = MenuUtils.get_file_name(gcs);
    CoCoSimPreferences = load_coco_preferences();
    if CoCoSimPreferences.lustreCompiler == 1
        ToLustre(mdl_full_path, [], bckend);
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

