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
    schema.label = 'For Verification';
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    schema.callback =  @(x) LusCompilerCallback(CoCoSimPreferences.lustreBackend, x);
end

function schema = getLustrec(varargin)
    schema = sl_action_schema;
    schema.label = 'For C code generation';
    schema.callback =  @(x) LusCompilerCallback(LusBackendType.LUSTREC, x);
end

function LusCompilerCallback(bckend, ~)
    try
        mdl_full_path = MenuUtils.get_file_name(gcs);
        MenuUtils.add_pp_warning(mdl_full_path);
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
        if isequal(CoCoSimPreferences.lustreCompiler, 'IOWA') 
            cocoSpecCompiler(mdl_full_path);
        else
            nasa_toLustre.ToLustre(mdl_full_path, [], bckend);
        end
    catch ME
        display_msg(ME.getReport(), Constants.DEBUG,'LusCompilerCallback','');
        display_msg(ME.message, Constants.ERROR,'LusCompilerCallback','');
    end
end

