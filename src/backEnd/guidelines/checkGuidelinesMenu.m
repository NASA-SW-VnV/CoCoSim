%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = checkGuidelinesMenu(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Check model against guidelines';
    schema.statustip = 'Check model against guidelines ';
    schema.autoDisableWhen = 'Busy';
    
    schema.callback = @checkGuidelinesCallback;
end

function checkGuidelinesCallback(callbackInfo)
    try
        model_full_path = MenuUtils.get_file_name(gcs);
        MenuUtils.add_pp_warning(model_full_path);
        check_guidelines(model_full_path);
        
    catch me
        MenuUtils.handleExceptionMessage(me, 'Check Guidelines');
    end
end