%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function schema = ppMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Pre-process this model';
schema.callback = @PPCallback;
end


function PPCallback(callbackInfo)
try
    model_full_path = MenuUtils.get_file_name(gcs) ;
    [new_file_path, status] = cocosim_pp(model_full_path);
    if status
        return;
    end
    display_msg(['your pre-processed model is : ', new_file_path], ...
        MsgType.RESULT, 'ppMenu','');
catch ME
    display_msg(ME.getReport(), MsgType.DEBUG,'ppMenu','');
    display_msg(ME.message, MsgType.ERROR,'ppMenu','');
end
end

