%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = lusVerifyMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Monolithic Verification';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@getZustre, @getKind, @getJKind};
schema.childrenFcns(numel(schema.childrenFcns)+1) = {@helpItem};

end

function  schema = helpItem(callbackInfo)
schema = sl_action_schema;
schema.label = 'Help';
schema.callback = @helpCallback;
end

function helpCallback(callbackInfo)
msg = sprintf('We recommend using Kind2 for compositional and contracts based Verification.');
msg = sprintf('%s\nZustre may be good for non-linear functions.', msg);
helpdlg(msg, 'CoCoSim help');
end


function schema = getZustre(callbackInfo)
schema = sl_action_schema;
schema.label = 'Zustre';
schema.callback = @zustreCallback;
end

function zustreCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'Z');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
runCoCoSim;
end


function schema = getKind(callbackInfo)
schema = sl_action_schema;
schema.label = 'Kind2';
schema.callback = @kindCallback;
end

function kindCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'K');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
runCoCoSim;
end

function schema = getJKind(callbackInfo)
schema = sl_action_schema;
schema.label = 'JKind';
schema.callback = @jkindCallback;
end

function jkindCallback(callbackInfo)
clear;
assignin('base', 'SOLVER', 'J');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
runCoCoSim;
end

function runCoCoSim
try
    simulink_name = MenuUtils.get_file_name(gcs);
    cocosim_window(simulink_name);
    %       cocoSim(simulink_name); % run cocosim
catch ME
    if strcmp(ME.identifier, 'MATLAB:badsubscript')
        msg = ['Activate debug message by running cocosim_debug=true', ...
            ' to get more information where the model in failing'];
        e_msg = sprintf('Error Msg: %s \n Action:\n\t %s', ME.message, msg);
        display_msg(e_msg, Constants.ERROR, 'cocoSim', '');
        display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
    elseif strcmp(ME.identifier,'MATLAB:MException:MultipleErrors')
        msg = 'Make sure that the model can be run (i.e. most probably missing constants)';
        d_msg = sprintf('Error Msg: %s', ME.getReport());
        display_msg(d_msg, Constants.DEBUG, 'cocoSim', '');
        display_msg(msg, Constants.ERROR, 'cocoSim', '');
    elseif strcmp(ME.identifier, 'Simulink:Commands:ParamUnknown')
        msg = 'Run CoCoSim on the most top block of the model';
        e_msg = sprintf('Error Msg: %s \n Action:\n\t %s', ME.message, msg);
        display_msg(e_msg, Constants.ERROR, 'cocoSim', '');
        display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
    else
        display_msg(ME.message,Constants.ERROR,'cocoSim','');
        display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
    end
    
end
end