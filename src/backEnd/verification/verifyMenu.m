function schema = verifyMenu(varargin)
schema = sl_container_schema;
schema.label = 'Prove properties using ...';
schema.statustip = 'Verify the current model with CoCoSim';
schema.autoDisableWhen = 'Busy';

[verif_root, ~, ~] = fileparts(mfilename('fullpath'));
verification_items{1} = fullfile(verif_root, 'lustreVerify', 'lusVerifyMenu.m');
verification_items{2} = fullfile(verif_root, 'cocoSpecVerify', 'cocoSpecVerifyMenu.m');
schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, verification_items,...
    'UniformOutput', false);
schema.childrenFcns(numel(schema.childrenFcns)+1) = {@helpItem};
end

function  schema = helpItem(varargin)
schema = sl_action_schema;
schema.label = 'Help';
schema.callback = @helpCallback;
end

function helpCallback(varargin)
msg = sprintf('We recommend using CoCoSpec compiler for compositional and contracts based Verification.');
msg = sprintf('%s\nWe recommend using Lustre compiler for multi-sampleTime Simulink models.', msg);
helpdlg(msg, 'CoCoSim help');
end