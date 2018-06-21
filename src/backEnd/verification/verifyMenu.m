function schema = verifyMenu(varargin)
schema = sl_container_schema;
schema.label = 'Prove properties using ...';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

% [verif_root, ~, ~] = fileparts(mfilename('fullpath'));
% verification_items{1} = fullfile(verif_root, 'lustreVerify', 'lusVerifyMenu.m');
% verification_items{2} = fullfile(verif_root, 'cocoSpecVerify', 'cocoSpecVerifyMenu.m');
schema.childrenFcns = {@getKind, @getZustre, @getJKind, @helpItem};

end



function schema = getZustre(varargin)
schema = sl_action_schema;
schema.label = 'Zustre';
schema.callback = @zustreCallback;
end

function zustreCallback(varargin)
clear;
assignin('base', 'SOLVER', 'Z');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
VerificationMenu.runCoCoSim;
end


function schema = getKind(varargin)
schema = sl_action_schema;
schema.label = 'Kind2';
schema.callback = @kindCallback;
end

function kindCallback(varargin)
clear;
model_full_path = MenuUtils.get_file_name(gcs);
[ CoCoSimPreferences ] = loadCoCoSimPreferences();
if CoCoSimPreferences.lustreCompiler ==1
    toLustreVerify(model_full_path);
elseif CoCoSimPreferences.lustreCompiler
    assignin('base', 'SOLVER', 'K');
    VerificationMenu.runCoCoSim;    
end
end

function schema = getJKind(varargin)
schema = sl_action_schema;
schema.label = 'JKind';
schema.callback = @jkindCallback;
end

function jkindCallback(varargin)
clear;
assignin('base', 'SOLVER', 'J');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
VerificationMenu.runCoCoSim;
end

function  schema = helpItem(varargin)
schema = sl_action_schema;
schema.label = 'Help';
schema.callback = @helpCallback;
end

function helpCallback(varargin)
msg = sprintf('We recommend using Kind2 for compositional and contracts based Verification.');
msg = sprintf('%s\nZustre may be good for non-linear functions.', msg);
helpdlg(msg, 'CoCoSim help');
end
