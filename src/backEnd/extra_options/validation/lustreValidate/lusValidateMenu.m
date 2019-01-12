%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = lusValidateMenu(varargin)
schema = sl_container_schema;
schema.label = 'Simulink to Lustre compiler using ...';
schema.statustip = 'Validate Lustre compiler';
schema.autoDisableWhen = 'Busy';

validationType = {'Random vector tests', 'Mutation based testing',...
    'Equivalence Checking using Simulink Design Verifier', ...
    'Equivalence Checking using Kind2'};
callbacks = {};
for i=1:4
    callbacks{end+1} = @(x) ValidateAction(validationType{i}, i, x);
end
schema.childrenFcns = callbacks;
end

function schema = ValidateAction(vType, vIndex, varargin)
schema = sl_action_schema;
schema.label = vType;
schema.callback = @(x) VCallback(vIndex, x);
end

function VCallback(tests_method, varargin)
try
    CoCoSimPreferences = load_coco_preferences();
    if CoCoSimPreferences.lustreCompiler ~= 1
        msgbox(...
            sprintf('This Functionality is only supported by the NASA Lustre compiler.\n Go to Tools -> Preferences -> Lustre Compiler -> NASA Compiler'), 'CoCoSim');
    else
        model_full_path = MenuUtils.get_file_name(gcs) ;
        validate_ToLustre(model_full_path, tests_method, 'KIND2', ...
            1);
    end
catch ME
    display_msg(ME.getReport(), Constants.DEBUG,'Validate_model','');
    display_msg(ME.message, Constants.ERROR,'Validate_model','');
end
end

