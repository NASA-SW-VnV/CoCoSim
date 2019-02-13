%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function schema = IRMenu(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Export model to JSON format';
    schema.callback = @IRCallback;
end


function IRCallback(callbackInfo)
    try
        model_full_path = MenuUtils.get_file_name(gcs) ;
        cocosim_IR( model_full_path, 1 );

        [parent, file_name, ~] = fileparts(model_full_path);
        json_path = fullfile(parent, [file_name '_IR.json']);
        display_msg(['JSON file is : ', json_path], ...
            MsgType.RESULT, 'IRMenu','');
    catch ME
        display_msg(ME.getReport(), MsgType.DEBUG,'IRMenu','');
        display_msg(ME.message, MsgType.ERROR,'IRMenu','');
    end
end

