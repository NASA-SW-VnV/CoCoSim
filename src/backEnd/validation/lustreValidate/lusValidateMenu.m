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
schema.callback = @V1Callback;
end

function V1Callback(callbackInfo)
try
    [cocoSim_path, ~, ~] = fileparts(mfilename('fullpath'));
    model_full_path = MenuUtils.get_file_name(gcs) ;
    L = log4m.getLogger(fullfile(fileparts(model_full_path),'logfile.txt'));
    validate_window(model_full_path,cocoSim_path,1,L);
catch ME
    display_msg(ME.getReport(), Constants.DEBUG,'Validate_model','');
    display_msg(ME.message, Constants.ERROR,'Validate_model','');
end
end