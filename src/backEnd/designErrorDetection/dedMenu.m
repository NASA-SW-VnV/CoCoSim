%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = dedMenu(~)
    schema = sl_action_schema;
    schema.label = 'Design Error Detection';
    schema.statustip = 'Detect Design Errors';
    schema.autoDisableWhen = 'Busy';
    schema.callback = @dedCallback;
end

function dedCallback(~)
    try
        [ CoCoSimPreferences ] = loadCoCoSimPreferences();
        model_full_path = MenuUtils.get_file_name(gcs);
        MenuUtils.add_pp_warning(model_full_path);
        lustreDED(model_full_path, [], CoCoSimPreferences.lustreBackend);
    catch me
        MenuUtils.handleExceptionMessage(me, 'Design Error Detection');
    end
end