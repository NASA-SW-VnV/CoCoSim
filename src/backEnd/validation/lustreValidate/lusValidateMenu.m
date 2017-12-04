%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = lusValidateMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Lustre compiler using ...';
schema.statustip = 'Validate Lustre compiler';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@Validate1};%, @Validate2, @Validate3};
end

function schema = Validate1(callbackInfo)
schema = sl_action_schema;
schema.label = 'Validation by random tests';
schema.callback = @(x) VCallback(1, x);
end

function VCallback(tests_method, callbackInfo)
try
    model_full_path = MenuUtils.get_file_name(gcs) ;
    validate_translation(model_full_path, tests_method, 'KIND2', ...
        1);
catch ME
    display_msg(ME.getReport(), Constants.DEBUG,'Validate_model','');
    display_msg(ME.message, Constants.ERROR,'Validate_model','');
end
end

