%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = PreludeMenu(varargin)
    schema = sl_action_schema;
    schema.label = 'Prelude';
    schema.callback =  @(x) PreludeCompilerCallback(LusBackendType.PRELUDE, x);
end

function PreludeCompilerCallback(bckend, ~)
    try
        mdl_full_path = MenuUtils.get_file_name(gcs);
        MenuUtils.add_pp_warning(mdl_full_path);
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
        if strcmp(CoCoSimPreferences.lustreCompiler, 'IOWA') 
            cocoSpecCompiler(mdl_full_path);
        else
            nasa_toLustre.ToLustre(mdl_full_path, [], bckend);
        end
    catch ME
        display_msg(ME.getReport(), Constants.DEBUG,'LusCompilerCallback','');
        display_msg(ME.message, Constants.ERROR,'LusCompilerCallback','');
    end
end

