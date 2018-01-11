%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = RustMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Rust';
schema.callback = @RustCallback;
end


function RustCallback(callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
try
    lus_full_path = lustre_compiler(model_full_path);
    output_dir = fullfile(fileparts(lus_full_path), 'Rust');
    generate_rust(lus_full_path, output_dir);
    
catch ME
    display_msg(ME.getReport(),  MsgType.DEBUG,'RustMenu','');
end
end