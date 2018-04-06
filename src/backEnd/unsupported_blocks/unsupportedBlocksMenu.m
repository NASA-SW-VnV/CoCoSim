%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = unsupportedBlocksMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Check Compatibility';
schema.callback = @UnsupportedFunctionCallback;
end

function UnsupportedFunctionCallback(callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
[model_dir, file_name, ~] = fileparts(model_full_path);
unsupportedOptions= ToLustreUnsupportedBlocks(model_full_path);
if isempty(unsupportedOptions)
    if exist('success.png', 'file')
        [icondata,iconcmap] = imread('success.png');
        msgbox('Your model is compatible with CoCoSim!','Success','custom',icondata,iconcmap);
    else
        msgbox('Your model is compatible with CoCoSim!');
    end
else
    try
        output_dir = fullfile(model_dir, 'cocosim_output', file_name);
        html_path = fullfile(output_dir, strcat(file_name, '_unsupportedOptions.html'));
        if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
        MenuUtils.createHtmlList('Unsupported options/blocks', unsupportedOptions, html_path);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'unsupportedBlocksMenu', '');
        msg = sprintf('Your model is incompatible with CoCoSim for the following reasons:\n%s', ...
            MatlabUtils.strjoin(unsupportedOptions, '\n\n'));
        msgbox(msg, 'Error','error');
    end
end
end